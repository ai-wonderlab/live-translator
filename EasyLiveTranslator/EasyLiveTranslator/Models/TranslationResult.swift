import Foundation

struct TranslationResult: Codable {
    let detected: String
    let translation: String
    let error: String?
    /// The transcript the service judged to be the one actually spoken.
    let source: String?
    /// The language the text was translated into.
    let translationLanguage: String?

    enum CodingKeys: String, CodingKey {
        case detected, translation, error, source
        case translationLanguage = "translation_language"
    }
}
