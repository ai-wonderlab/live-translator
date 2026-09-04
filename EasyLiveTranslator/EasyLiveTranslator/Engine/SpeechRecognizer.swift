import AVFoundation
import Foundation
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

/// What was heard, and in which language the recognizer read it.
struct RecognizedSpeech {
    let text: String
    let language: Language
}

/// Records an utterance, then transcribes the recording once per candidate
/// language.
///
/// Listening with several live recognizers at once seemed obvious but does not
/// work: Apple's speech servers reject concurrent requests
/// (kAFAssistantErrorDomain 1011), so whichever language lacked an on-device
/// model silently produced nothing — and a language that produced nothing can
/// never be chosen, no matter how good the selection logic downstream is.
/// Transcribing a recording one language at a time gives every candidate the
/// same audio and a fair chance.
final class SpeechRecognizer {

    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
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

    /// Starts recording. Nothing is transcribed until `stopListening`.
    func startListening() throws {
        cleanupAudio()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("utterance-\(UUID().uuidString).caf")
        audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        recordingURL = url

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            try? self.audioFile?.write(from: buffer)

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
    }

    /// Stops recording and returns one transcript per language that produced
    /// speech, in the order the languages were given.
    func stopListening(languages: [Language]) async throws -> [RecognizedSpeech] {
        audioEngine.stop()
        removeTapIfInstalled()
        onAudioLevel?(0)
        audioFile = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let url = recordingURL else { throw SpeechRecognizerError.emptyTranscript }
        defer {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }

        var results: [RecognizedSpeech] = []
        for language in languages {
            if let heard = await transcribe(url: url, language: language) {
                debugLog("[STT] \(language.code): \(heard.text)")
                results.append(heard)
            } else {
                debugLog("[STT] \(language.code): —")
            }
        }

        guard !results.isEmpty else { throw SpeechRecognizerError.emptyTranscript }
        return results
    }

    // MARK: - Private

    private func transcribe(url: URL, language: Language) async -> RecognizedSpeech? {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeIdentifier)),
              recognizer.isAvailable else { return nil }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        return await withCheckedContinuation { continuation in
            let box = ResumeOnce(continuation)
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    box.resume(with: text.isEmpty ? nil : RecognizedSpeech(text: text, language: language))
                } else if let error {
                    debugLog("[STT] \(language.code) failed: \(error.localizedDescription)")
                    box.resume(with: nil)
                }
            }

            // A recognizer that never calls back must not stall the whole turn.
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                if box.resume(with: nil) { task.cancel() }
            }
        }
    }

    /// Guarantees a continuation is resumed exactly once, from any queue.
    private final class ResumeOnce {
        private let continuation: CheckedContinuation<RecognizedSpeech?, Never>
        private let lock = NSLock()
        private var done = false

        init(_ continuation: CheckedContinuation<RecognizedSpeech?, Never>) {
            self.continuation = continuation
        }

        @discardableResult
        func resume(with value: RecognizedSpeech?) -> Bool {
            lock.lock()
            if done { lock.unlock(); return false }
            done = true
            lock.unlock()
            continuation.resume(returning: value)
            return true
        }
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
        audioFile = nil
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
