import Foundation
import Combine

@MainActor
final class TranslationEngine: ObservableObject {
    /// The user's own language (from the device) and the language they chose to
    /// translate into.
    var langA: Language = .greek
    var langB: Language = .english

    /// Languages the recognizer listens for at the same time: the user's own,
    /// the chosen target, and English — the common travel fallback for someone
    /// speaking neither of the other two.
    ///
    /// English only earns its place when it is neither of the first two, so it
    /// carries a penalty: it should win when someone genuinely speaks English,
    /// not because it happened to score a hair higher on Greek audio.
    private var speechCandidates: [SpeechCandidate] {
        var seen = Set<String>()
        var candidates: [SpeechCandidate] = []
        for (language, bias) in [(langA, 0.10), (langB, 0.05), (Language.english, -0.20)] {
            guard seen.insert(language.code).inserted else { continue }
            candidates.append(SpeechCandidate(language: language, bias: bias))
        }
        return candidates
    }

    /// What a spoken utterance should be translated into: the chosen target,
    /// unless the target is what was just spoken — then it is a reply, and it
    /// goes back to the user's own language.
    private func destination(for spoken: Language) -> Language {
        spoken == langB ? langA : langB
    }


    @Published var sourceLanguage: Language = .greek
    @Published var targetLanguage: Language = .english
    @Published var transcript = ""
    @Published var translationText = ""
    @Published var detectedLanguage: Language? = nil
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var isPreparingPermissions = false
    @Published var errorMessage: String?
    private var lastTranslationAt: Date = .distantPast
    private var holdStartedAt: Date = .distantPast
    // Short debounce against accidental double-taps; isProcessing already guards overlap.
    private static let translationCooldown: TimeInterval = 0.4
    @Published private(set) var history: [TranslationEntry] = []
    @Published var permissionsGranted = false

    private let speechRecognizer = SpeechRecognizer()
    private let api = TranslationAPI()
    private let appleTranslation = AppleTranslationProvider()
    private let speechSynthesizer = SpeechSynthesizer()
    private let credits = CreditManager.shared
    private var hasPreparedPermissions = false

    var statusText: String {
        if let errorMessage {
            return errorMessage
        }
        if isPreparingPermissions {
            return "Requesting microphone and speech recognition access..."
        }
        if !permissionsGranted {
            return "Microphone and speech recognition access are required."
        }
        if isProcessing {
            return "Translating..."
        }
        if isListening {
            return "Listening..."
        }
        return "Hold the button, speak in \(sourceLanguage.displayName), then release."
    }

    func prepareForLaunch() async {
        guard !hasPreparedPermissions else { return }
        hasPreparedPermissions = true
        isPreparingPermissions = true
        errorMessage = nil
        permissionsGranted = await speechRecognizer.requestPermissions()
        isPreparingPermissions = false
        if !permissionsGranted {
            errorMessage = "Permissions were not granted."
        }
    }

    func swapLanguages() {
        guard !isListening, !isProcessing else { return }
        (sourceLanguage, targetLanguage) = (targetLanguage, sourceLanguage)
        transcript = ""
        translationText = ""
        detectedLanguage = nil
        errorMessage = nil
    }

    func beginHoldIfNeeded() {
        guard permissionsGranted, !isPreparingPermissions, !isListening, !isProcessing,
              Date().timeIntervalSince(lastTranslationAt) >= Self.translationCooldown else { return }
        do {
            transcript = ""
            translationText = ""
            detectedLanguage = nil
            errorMessage = nil
            // Listen in every candidate language at once; which one was really
            // spoken is settled after transcription, not guessed beforehand.
            try speechRecognizer.startListening(candidates: speechCandidates)
            holdStartedAt = Date()
            isListening = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endHold() async {
        guard isListening else { return }

        isListening = false
        isProcessing = true
        errorMessage = nil

        let startedAt = Date()
        let recordingSeconds = startedAt.timeIntervalSince(holdStartedAt)

        do {
            let heard = try await speechRecognizer.stopListening()
            guard let leading = heard.first else {
                throw SpeechRecognizerError.emptyTranscript
            }

            guard credits.hasCredits else {
                throw TranslationCreditError.noCredits
            }

            let response: TranslationResult
            if heard.count == 1,
               let onDevice = await appleTranslation.translate(
                   text: leading.text,
                   langA: leading.language.code,
                   langB: destination(for: leading.language).code
               ) {
                // Only safe on-device when a single recognizer produced text —
                // choosing between competing transcripts needs the service.
                debugLog("[Engine] Translated on-device")
                response = onDevice
            } else {
                response = try await api.translate(
                    candidates: heard,
                    target: langB,
                    home: langA
                )
            }

            let spokenLang = Language(code: response.detected) ?? leading.language
            let translateTo = Language(code: response.translationLanguage ?? "")
                ?? destination(for: spokenLang)

            transcript = response.source ?? leading.text
            detectedLanguage = spokenLang
            sourceLanguage = spokenLang
            targetLanguage = translateTo
            translationText = response.translation
            debugLog("[Engine] \(spokenLang.code) → \(translateTo.code): \(transcript)")

            credits.deduct(recordingSeconds: recordingSeconds)
            lastTranslationAt = Date()
            history.insert(
                TranslationEntry(
                    spokenText: transcript,
                    translatedText: response.translation,
                    sourceLanguage: spokenLang,
                    targetLanguage: translateTo,
                    date: Date()
                ),
                at: 0
            )
            await speechSynthesizer.speak(response.translation, language: translateTo)

            let elapsed = Date().timeIntervalSince(startedAt)
            debugLog(String(format: "[TIMING] Total: %.1fs (recorded %.1fs)", elapsed, recordingSeconds))
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}

enum TranslationCreditError: LocalizedError {
    case noCredits

    var errorDescription: String? {
        switch self {
        case .noCredits:
            return "No translation credits remaining. Add more time to continue."
        }
    }
}
