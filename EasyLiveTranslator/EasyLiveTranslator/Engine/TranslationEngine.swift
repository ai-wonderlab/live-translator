import Foundation
import Combine

@MainActor
final class TranslationEngine: ObservableObject {
    // Conversation pair — set from HomeView via AppStorage
    var langA: Language = .greek
    var langB: Language = .english

    // Active STT language — alternates after each translation
    var activeSttLanguage: Language = .greek

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
            try speechRecognizer.startListening(language: activeSttLanguage)
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
            let recognized = try await speechRecognizer.stopListening()
            transcript = recognized
            debugLog("[STT] Recognized: \(recognized)")

            guard credits.hasCredits else {
                throw TranslationCreditError.noCredits
            }

            // On-device first (free, offline, instant); cloud backend as fallback.
            let response: TranslationResult
            if let onDevice = await appleTranslation.translate(
                text: recognized,
                langA: langA.code,
                langB: langB.code
            ) {
                debugLog("[Engine] Translated on-device")
                response = onDevice
            } else {
                response = try await api.translate(
                    text: recognized,
                    langA: langA,
                    langB: langB
                )
            }
            translationText = response.translation
            let detected = Language(code: response.detected ?? "") ?? activeSttLanguage
            detectedLanguage = detected

            // Conversation mode: if A spoke → next time listen for B, and vice versa
            let spokenLang = detected
            let translateTo = (spokenLang == langA) ? langB : langA
            activeSttLanguage = translateTo  // next speaker speaks the other language

            credits.deduct(recordingSeconds: recordingSeconds)
            lastTranslationAt = Date()
            history.insert(
                TranslationEntry(
                    spokenText: recognized,
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
