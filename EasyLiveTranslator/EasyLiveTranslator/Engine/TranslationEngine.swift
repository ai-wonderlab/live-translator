import Foundation
import Combine

@MainActor
final class TranslationEngine: ObservableObject {
    @Published var sourceLanguage: Language = .greek
    @Published var targetLanguage: Language = .english
    @Published var transcript = ""
    @Published var translationText = ""
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var isPreparingPermissions = false
    @Published var errorMessage: String?
    private var lastTranslationAt: Date = .distantPast
    private static let translationCooldown: TimeInterval = 2.0
    @Published private(set) var history: [TranslationEntry] = []
    @Published var permissionsGranted = false

    private let speechRecognizer = SpeechRecognizer()
    private let api = TranslationAPI()
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
            return "Listening in \(sourceLanguage.displayName)..."
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
        errorMessage = nil
    }

    func beginHoldIfNeeded() {
        guard permissionsGranted, !isPreparingPermissions, !isListening, !isProcessing,
              Date().timeIntervalSince(lastTranslationAt) >= Self.translationCooldown else { return }
        do {
            transcript = ""
            translationText = ""
            errorMessage = nil
            // Auto-detect: use device locale for STT; OpenAI detects actual language
            let localeCode = Locale.current.language.languageCode?.identifier ?? ""
            let sttLanguage = Language(code: localeCode) ?? sourceLanguage
            try speechRecognizer.startListening(language: sttLanguage)
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

        do {
            let recognized = try await speechRecognizer.stopListening()
            transcript = recognized
            print("[STT] Recognized: \(recognized)")

            guard credits.hasCredits else {
                throw TranslationCreditError.noCredits
            }

            let response = try await api.translate(
                text: recognized,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            translationText = response.translation
            // If backend detected the opposite language, silently swap source/target
            if let detectedLanguage = Language(code: response.detected),
               detectedLanguage != sourceLanguage {
                (sourceLanguage, targetLanguage) = (targetLanguage, sourceLanguage)
            }
            credits.deductTranslation()
            lastTranslationAt = Date()
            history.insert(
                TranslationEntry(
                    spokenText: recognized,
                    translatedText: response.translation,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    date: Date()
                ),
                at: 0
            )
            await speechSynthesizer.speak(response.translation, language: targetLanguage)

            let elapsed = Date().timeIntervalSince(startedAt)
            print(String(format: "[TIMING] Total: %.1fs", elapsed))
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
