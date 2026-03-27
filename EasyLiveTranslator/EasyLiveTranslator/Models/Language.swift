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
    case albanian = "sq"
    case bulgarian = "bg"
    case catalan = "ca"
    case chineseSimplified = "zh"
    case chineseTraditional = "zh-TW"
    case croatian = "hr"
    case czech = "cs"
    case filipino = "fil"
    case hebrew = "he"
    case hungarian = "hu"
    case indonesian = "id"
    case malay = "ms"
    case romanian = "ro"
    case serbian = "sr"
    case slovak = "sk"
    case thai = "th"
    case ukrainian = "uk"
    case vietnamese = "vi"

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
        case .albanian:
            return "sq-AL"
        case .bulgarian:
            return "bg-BG"
        case .catalan:
            return "ca-ES"
        case .chineseSimplified:
            return "zh-CN"
        case .chineseTraditional:
            return "zh-TW"
        case .croatian:
            return "hr-HR"
        case .czech:
            return "cs-CZ"
        case .filipino:
            return "fil-PH"
        case .hebrew:
            return "he-IL"
        case .hungarian:
            return "hu-HU"
        case .indonesian:
            return "id-ID"
        case .malay:
            return "ms-MY"
        case .romanian:
            return "ro-RO"
        case .serbian:
            return "sr-RS"
        case .slovak:
            return "sk-SK"
        case .thai:
            return "th-TH"
        case .ukrainian:
            return "uk-UA"
        case .vietnamese:
            return "vi-VN"
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
        case .albanian:
            return "Albanian"
        case .bulgarian:
            return "Bulgarian"
        case .catalan:
            return "Catalan"
        case .chineseSimplified:
            return "Chinese (Simplified)"
        case .chineseTraditional:
            return "Chinese (Traditional)"
        case .croatian:
            return "Croatian"
        case .czech:
            return "Czech"
        case .filipino:
            return "Filipino"
        case .hebrew:
            return "Hebrew"
        case .hungarian:
            return "Hungarian"
        case .indonesian:
            return "Indonesian"
        case .malay:
            return "Malay"
        case .romanian:
            return "Romanian"
        case .serbian:
            return "Serbian"
        case .slovak:
            return "Slovak"
        case .thai:
            return "Thai"
        case .ukrainian:
            return "Ukrainian"
        case .vietnamese:
            return "Vietnamese"
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
        case .albanian:
            return "🇦🇱"
        case .bulgarian:
            return "🇧🇬"
        case .catalan:
            return "🏴󠁥󠁳󠁣󠁴󠁿"
        case .chineseSimplified:
            return "🇨🇳"
        case .chineseTraditional:
            return "🇹🇼"
        case .croatian:
            return "🇭🇷"
        case .czech:
            return "🇨🇿"
        case .filipino:
            return "🇵🇭"
        case .hebrew:
            return "🇮🇱"
        case .hungarian:
            return "🇭🇺"
        case .indonesian:
            return "🇮🇩"
        case .malay:
            return "🇲🇾"
        case .romanian:
            return "🇷🇴"
        case .serbian:
            return "🇷🇸"
        case .slovak:
            return "🇸🇰"
        case .thai:
            return "🇹🇭"
        case .ukrainian:
            return "🇺🇦"
        case .vietnamese:
            return "🇻🇳"
        }
    }
}
