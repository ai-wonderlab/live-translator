import AVFoundation
import Foundation
import Speech

enum SpeechRecognizerError: LocalizedError {
    case unavailableRecognizer
    case missingRequest
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .unavailableRecognizer:
            return "Speech recognizer is unavailable for the selected language."
        case .missingRequest:
            return "Speech recognition request could not be created."
        case .emptyTranscript:
            return "No speech was recognized."
        }
    }
}

final class SpeechRecognizer {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var finalContinuation: CheckedContinuation<String, Error>?
    private var latestTranscript = ""
    private var tapInstalled = false

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

    func startListening(language: Language) throws {
        resetSession()

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeIdentifier))
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechRecognizerError.unavailableRecognizer
        }

        speechRecognizer = recognizer
        latestTranscript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        tapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // Dispatch to main to avoid data races on all properties
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let result {
                    self.latestTranscript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.finishRecognition(self.latestTranscript)
                        return  // don't fall through to error check
                    }
                }

                if let error {
                    self.finishRecognition(error: error)
                }
            }
        }
    }

    func stopListening() async throws -> String {
        guard audioEngine.isRunning else {
            let transcript = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !transcript.isEmpty else { throw SpeechRecognizerError.emptyTranscript }
            return transcript
        }

        audioEngine.stop()
        removeTapIfInstalled()
        recognitionRequest?.endAudio()

        return try await withCheckedThrowingContinuation { continuation in
            finalContinuation = continuation

            // Always add a safety timeout — prevents hanging continuation
            // (fires when: quick release with no speech, recognition task stalls)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self, self.finalContinuation != nil else { return }
                let transcript = self.latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                if transcript.isEmpty {
                    self.finishRecognition(error: SpeechRecognizerError.emptyTranscript)
                } else {
                    self.finishRecognition(transcript)
                }
            }
        }
    }

    // MARK: - Private

    private func finishRecognition(_ transcript: String) {
        guard finalContinuation != nil else { return }
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            finishRecognition(error: SpeechRecognizerError.emptyTranscript)
            return
        }
        cleanupAudio()
        finalContinuation?.resume(returning: trimmed)
        finalContinuation = nil
    }

    private func finishRecognition(error: Error) {
        guard finalContinuation != nil else { return }
        cleanupAudio()
        finalContinuation?.resume(throwing: error)
        finalContinuation = nil
    }

    private func resetSession() {
        cleanupAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        finalContinuation = nil
        latestTranscript = ""
    }

    private func removeTapIfInstalled() {
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
    }

    private func cleanupAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        removeTapIfInstalled()
        recognitionRequest?.endAudio()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
