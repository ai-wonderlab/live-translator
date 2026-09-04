import Foundation
import Translation
import NaturalLanguage

/// On-device translation via Apple's Translation framework.
///
/// Free, offline, and faster than any network round-trip. Uses the iOS 26
/// `TranslationSession(installedSource:target:)` initializer, which only works
/// when the language pair's models are already installed on the device.
/// Returns nil for unsupported pairs, missing downloads, or any failure —
/// signaling the caller to fall back to the cloud backend. The user never
/// sees an error from this path.
struct AppleTranslationProvider {

    // App language codes (Language.code) that Apple Translation may cover
    // (per the Translate app's language list). This is only a pre-filter —
    // LanguageAvailability.status() is the runtime source of truth, so an
    // entry that isn't actually available simply falls back to cloud.
    private static let supported: Set<String> = [
        "ar", "ca", "cs", "da", "nl", "en", "fi", "fr", "de", "el", "he",
        "hi", "id", "it", "ja", "ko", "ms", "no", "pl", "pt", "ro", "ru",
        "sk", "es", "sv", "th", "tr", "uk", "vi", "zh", "zh-TW"
    ]

    // Map app language codes to Apple Locale.Language identifiers.
    private static func appleLanguage(for code: String) -> Locale.Language {
        switch code {
        case "zh":    return Locale.Language(identifier: "zh-Hans")
        case "zh-TW": return Locale.Language(identifier: "zh-Hant")
        default:      return Locale.Language(identifier: code)
        }
    }

    /// Translates on-device. Returns nil when the caller should use the backend.
    ///
    /// On iOS < 26 the required `TranslationSession(installedSource:target:)`
    /// initializer does not exist, so every call falls through to the cloud path.
    @MainActor
    func translate(text: String, langA: String, langB: String) async -> TranslationResult? {
        guard #available(iOS 26.0, *) else { return nil }
        guard Self.supported.contains(langA), Self.supported.contains(langB) else {
            return nil
        }

        let sourceLang = detectSpokenLanguage(in: text, langA: langA, langB: langB) ?? langA
        let targetLang = sourceLang == langA ? langB : langA

        let source = Self.appleLanguage(for: sourceLang)
        let target = Self.appleLanguage(for: targetLang)

        // Only translate on-device when the models are already installed.
        // (.supported means downloadable — downloading needs a user prompt,
        // so we fall back to cloud instead of blocking the conversation.)
        let availability = LanguageAvailability()
        let status = await availability.status(from: source, to: target)
        guard status == .installed else { return nil }

        do {
            let session = try TranslationSession(installedSource: source, target: target)
            let response = try await session.translate(text)
            return TranslationResult(
                detected: sourceLang,
                translation: response.targetText,
                error: nil
            )
        } catch {
            debugLog("[Apple] On-device translation failed, using backend: \(error.localizedDescription)")
            return nil
        }
    }

    // Identifies which of the two conversation languages was spoken.
    private func detectSpokenLanguage(in text: String, langA: String, langB: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 10)
        for (nlLang, _) in hypotheses.sorted(by: { $0.value > $1.value }) {
            for candidate in [langA, langB] where nlCodeMatches(nlLang.rawValue, appCode: candidate) {
                return candidate
            }
        }
        return nil
    }

    private func nlCodeMatches(_ nlCode: String, appCode: String) -> Bool {
        if nlCode == appCode { return true }
        if appCode == "zh" && nlCode.hasPrefix("zh-Hans") { return true }
        if appCode == "zh-TW" && nlCode.hasPrefix("zh-Hant") { return true }
        if nlCode.hasPrefix(appCode + "-") { return true }
        return false
    }
}
