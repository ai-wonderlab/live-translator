import Translation
import NaturalLanguage

/// On-device translation using Apple's Translation framework (iOS 17.4+).
/// Covers a subset of languages. Returns nil for unsupported pairs so the
/// caller can fall back to the cloud backend.
@available(iOS 17.4, *)
struct AppleTranslationProvider {

    // App language codes (Language.code) supported by Apple Translation
    private static let supported: Set<String> = [
        "ar", "zh", "zh-TW", "nl", "en", "fr", "de", "id", "it",
        "ja", "ko", "pl", "pt", "ru", "es", "th", "tr", "uk", "vi"
    ]

    // Map app language codes to Apple Locale.Language identifiers
    private static func appleLocale(for code: String) -> Locale.Language {
        switch code {
        case "zh":    return Locale.Language(identifier: "zh-Hans")
        case "zh-TW": return Locale.Language(identifier: "zh-Hant")
        default:      return Locale.Language(identifier: code)
        }
    }

    /// Translates text on-device. Returns nil if the pair is unsupported or
    /// translation fails, signaling the caller to use the backend instead.
    @MainActor
    func translate(text: String, langA: String, langB: String) async -> TranslationResult? {
        guard Self.supported.contains(langA), Self.supported.contains(langB) else {
            return nil
        }

        let sourceLang = detectSpokenLanguage(in: text, langA: langA, langB: langB) ?? langA
        let targetLang = sourceLang == langA ? langB : langA

        let sourceLocale = Self.appleLocale(for: sourceLang)
        let targetLocale = Self.appleLocale(for: targetLang)

        let availability = LanguageAvailability()
        let status = await availability.status(from: sourceLocale, to: targetLocale)
        guard status != .unsupported else { return nil }

        do {
            let session = TranslationSession(source: sourceLocale, target: targetLocale)
            let response = try await session.translate(text)
            print("[Apple] ← {detected: \(sourceLang), translation: \(response.targetText)}")
            return TranslationResult(detected: sourceLang, translation: response.targetText, error: nil)
        } catch {
            print("[Apple] Translation failed, falling back to backend: \(error.localizedDescription)")
            return nil
        }
    }

    // Identifies which of the two conversation languages was spoken using NLLanguageRecognizer
    private func detectSpokenLanguage(in text: String, langA: String, langB: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 10)
        for (nlLang, _) in hypotheses.sorted(by: { $0.value > $1.value }) {
            let nlCode = nlLang.rawValue
            for candidate in [langA, langB] where nlCodeMatches(nlCode, appCode: candidate) {
                return candidate
            }
        }
        return nil
    }

    // Match NLLanguageRecognizer output (e.g. "zh-Hans") to an app language code (e.g. "zh")
    private func nlCodeMatches(_ nlCode: String, appCode: String) -> Bool {
        if nlCode == appCode { return true }
        if appCode == "zh" && (nlCode == "zh-Hans" || nlCode.hasPrefix("zh-Hans")) { return true }
        if appCode == "zh-TW" && (nlCode == "zh-Hant" || nlCode.hasPrefix("zh-Hant")) { return true }
        if nlCode.hasPrefix(appCode + "-") { return true }
        return false
    }
}
