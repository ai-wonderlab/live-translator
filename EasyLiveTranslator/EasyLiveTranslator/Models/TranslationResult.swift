import Foundation

struct TranslationResult: Codable {
    let detected: String
    let translation: String
    let error: String?
}
