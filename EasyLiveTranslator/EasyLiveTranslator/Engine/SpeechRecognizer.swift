import AVFoundation
import Foundation
import NaturalLanguage
import Speech

enum SpeechRecognizerError: LocalizedError {
    case unavailableRecognizer
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .unavailableRecognizer:
            return "Speech recognition is unavailable for the selected languages."
        case .emptyTranscript:
            return "No speech was recognized."
        }
    }
}

/// What was heard, and in which language it was actually spoken.
struct RecognizedSpeech {
    let text: String
    let language: Language
}

/// A language to listen for, with how strongly it is expected.
///
/// `bias` is added to the candidate's score, so a language that is only a
/// fallback (English, when the user speaks neither their own language nor the
/// target) has to win clearly rather than by a rounding error.
struct SpeechCandidate {
    let language: Language
    let bias: Double
}

/// Listens in several languages at once and returns the most confident result.
///
/// `SFSpeechRecognizer` must be told which language to expect, so a single
/// recognizer locked to one language mis-transcribes everything else (English
/// speech comes back as Greek-looking nonsense). Running one recognizer per
/// candidate language over the same audio buffer and scoring the results is
/// what makes "just talk, it figures out the language" actually work.
final class SpeechRecognizer {

    private final class Session {
        let language: Language
        let bias: Double
        let recognizer: SFSpeechRecognizer
        let request = SFSpeechAudioBufferRecognitionRequest()
        var task: SFSpeechRecognitionTask?
        var transcript = ""
        var confidence: Float = 0
        var isFinished = false

        init(language: Language, bias: Double, recognizer: SFSpeechRecognizer) {
            self.language = language
            self.bias = bias
            self.recognizer = recognizer
        }
    }

    private let audioEngine = AVAudioEngine()
    private var sessions: [Session] = []
    private var finalContinuation: CheckedContinuation<RecognizedSpeech, Error>?
    private var tapInstalled = false
    var onAudioLevel: ((Float) -> Void)?

    func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micAuthorized = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        return speechAuthorized && micAuthorized
    }

    /// Starts listening for every candidate at the same time.
    func startListening(candidates: [SpeechCandidate]) throws {
        resetSession()

        var started: [Session] = []
        for candidate in candidates {
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: candidate.language.localeIdentifier)),
                  recognizer.isAvailable else { continue }
            started.append(Session(language: candidate.language, bias: candidate.bias, recognizer: recognizer))
        }
        guard !started.isEmpty else { throw SpeechRecognizerError.unavailableRecognizer }
        sessions = started

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            for session in self.sessions {
                session.request.append(buffer)
            }
            // RMS level for the waveform.
            if let channelData = buffer.floatChannelData?[0] {
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else { return }
                var sum: Float = 0
                for i in 0..<frameLength { sum += channelData[i] * channelData[i] }
                let rms = sqrt(sum / Float(frameLength))
                let db = 20 * log10(max(rms, 1e-7))
                let normalized = Float(max(0.0, min(1.0, (db + 50) / 50)))
                DispatchQueue.main.async { self.onAudioLevel?(normalized) }
            }
        }
        tapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()

        for session in sessions {
            session.request.shouldReportPartialResults = true
            // Server recognition on purpose: on-device results frequently carry
            // zero per-segment confidence, and confidence is exactly what tells
            // the right recognizer apart from one forcing foreign audio into its
            // own language.
            session.request.requiresOnDeviceRecognition = false

            session.task = session.recognizer.recognitionTask(with: session.request) { [weak self, weak session] result, error in
                DispatchQueue.main.async {
                    guard let self, let session else { return }

                    if let result {
                        session.transcript = result.bestTranscription.formattedString
                        let segments = result.bestTranscription.segments
                        if !segments.isEmpty {
                            session.confidence = segments.map(\.confidence).reduce(0, +) / Float(segments.count)
                        }
                        if result.isFinal {
                            session.isFinished = true
                            self.finishIfAllSettled()
                            return
                        }
                    }

                    if error != nil {
                        session.isFinished = true
                        self.finishIfAllSettled()
                    }
                }
            }
        }
    }

    func stopListening() async throws -> RecognizedSpeech {
        guard audioEngine.isRunning else {
            guard let best = bestCandidate() else { throw SpeechRecognizerError.emptyTranscript }
            return best
        }

        audioEngine.stop()
        removeTapIfInstalled()
        for session in sessions { session.request.endAudio() }
        onAudioLevel?(0)

        return try await withCheckedThrowingContinuation { continuation in
            finalContinuation = continuation

            // Safety net: never leave the continuation hanging if a recognizer stalls.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self, self.finalContinuation != nil else { return }
                self.deliverResult()
            }
        }
    }

    // MARK: - Private

    private func finishIfAllSettled() {
        guard finalContinuation != nil else { return }
        guard sessions.allSatisfy(\.isFinished) else { return }
        deliverResult()
    }

    private func deliverResult() {
        guard let continuation = finalContinuation else { return }
        finalContinuation = nil
        cleanupAudio()

        if let best = bestCandidate() {
            continuation.resume(returning: best)
        } else {
            continuation.resume(throwing: SpeechRecognizerError.emptyTranscript)
        }
    }

    /// Picks the language whose recognizer produced the most plausible transcript.
    ///
    /// A recognizer forced to transcribe audio in a language it does not know
    /// still returns words — but with visibly lower confidence than the one that
    /// actually matches. Confidence carries the decision; a language identifier
    /// run over the transcript and the candidate's own bias break near-ties.
    private func bestCandidate() -> RecognizedSpeech? {
        var best: (score: Double, speech: RecognizedSpeech)?

        for session in sessions {
            let text = session.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            var score = Double(session.confidence)
            score += 0.30 * languageProbability(of: session.language, in: text)
            score += session.bias
            // Slight preference for the longer transcript — a mismatched
            // recognizer usually drops words it cannot map.
            score += min(Double(text.count), 60) / 600

            debugLog(String(format: "[STT] %@ score %.2f (conf %.2f): %@",
                            session.language.code, score, session.confidence, text))

            if best == nil || score > best!.score {
                best = (score, RecognizedSpeech(text: text, language: session.language))
            }
        }

        return best?.speech
    }

    /// How strongly a language identifier believes `text` is in `language`.
    private func languageProbability(of language: Language, in text: String) -> Double {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 8)

        var total = 0.0
        for (candidate, probability) in hypotheses where matches(candidate.rawValue, language) {
            total += probability
        }
        return total
    }

    private func matches(_ nlCode: String, _ language: Language) -> Bool {
        if language == .chineseTraditional { return nlCode.hasPrefix("zh-Hant") }
        if language == .chineseSimplified { return nlCode.hasPrefix("zh") && !nlCode.hasPrefix("zh-Hant") }
        if nlCode == language.code { return true }
        return nlCode.hasPrefix(language.code + "-")
    }

    private func resetSession() {
        cleanupAudio()
        for session in sessions { session.task?.cancel() }
        sessions = []
        finalContinuation = nil
    }

    private func removeTapIfInstalled() {
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
    }

    private func cleanupAudio() {
        if audioEngine.isRunning { audioEngine.stop() }
        removeTapIfInstalled()
        for session in sessions { session.request.endAudio() }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
