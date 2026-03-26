import Foundation

enum Language: String, CaseIterable, Identifiable {
    case arabic = "ar"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case finnish = "fi"
    case french = "fr"
    case german = "de"
    case greek = "el"
    case hindi = "hi"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case norwegian = "no"
    case polish = "pl"
    case portuguese = "pt"
    case russian = "ru"
    case spanish = "es"
    case swedish = "sv"
    case turkish = "tr"
    case chineseSimplified = "zh"

    var id: String { code }

    init?(code: String) {
        self.init(rawValue: code)
    }

    var code: String {
        rawValue
    }

    var localeIdentifier: String {
        switch self {
        case .arabic:
            return "ar-SA"
        case .danish:
            return "da-DK"
        case .dutch:
            return "nl-NL"
        case .english:
            return "en-US"
        case .finnish:
            return "fi-FI"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        case .greek:
            return "el-GR"
        case .hindi:
            return "hi-IN"
        case .italian:
            return "it-IT"
        case .japanese:
            return "ja-JP"
        case .korean:
            return "ko-KR"
        case .norwegian:
            return "nb-NO"
        case .polish:
            return "pl-PL"
        case .portuguese:
            return "pt-PT"
        case .russian:
            return "ru-RU"
        case .spanish:
            return "es-ES"
        case .swedish:
            return "sv-SE"
        case .turkish:
            return "tr-TR"
        case .chineseSimplified:
            return "zh-CN"
        }
    }

    var displayName: String {
        switch self {
        case .arabic:
            return "Arabic"
        case .danish:
            return "Danish"
        case .dutch:
            return "Dutch"
        case .english:
            return "English"
        case .finnish:
            return "Finnish"
        case .french:
            return "French"
        case .german:
            return "German"
        case .greek:
            return "Greek"
        case .hindi:
            return "Hindi"
        case .italian:
            return "Italian"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .norwegian:
            return "Norwegian"
        case .polish:
            return "Polish"
        case .portuguese:
            return "Portuguese"
        case .russian:
            return "Russian"
        case .spanish:
            return "Spanish"
        case .swedish:
            return "Swedish"
        case .turkish:
            return "Turkish"
        case .chineseSimplified:
            return "Chinese"
        }
    }

    var flag: String {
        switch self {
        case .arabic:
            return "🇸🇦"
        case .danish:
            return "🇩🇰"
        case .dutch:
            return "🇳🇱"
        case .english:
            return "🇺🇸"
        case .finnish:
            return "🇫🇮"
        case .french:
            return "🇫🇷"
        case .german:
            return "🇩🇪"
        case .greek:
            return "🇬🇷"
        case .hindi:
            return "🇮🇳"
        case .italian:
            return "🇮🇹"
        case .japanese:
            return "🇯🇵"
        case .korean:
            return "🇰🇷"
        case .norwegian:
            return "🇳🇴"
        case .polish:
            return "🇵🇱"
        case .portuguese:
            return "🇵🇹"
        case .russian:
            return "🇷🇺"
        case .spanish:
            return "🇪🇸"
        case .swedish:
            return "🇸🇪"
        case .turkish:
            return "🇹🇷"
        case .chineseSimplified:
            return "🇨🇳"
        }
    }
}
