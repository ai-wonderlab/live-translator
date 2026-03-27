import Foundation

struct TranslationEntry: Identifiable {
    let id = UUID()
    let spokenText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let date: Date
}
