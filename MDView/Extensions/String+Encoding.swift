import Foundation

extension String.Encoding {
    var displayName: String {
        switch self {
        case .utf8: return "UTF-8"
        case .utf16: return "UTF-16"
        case .utf16LittleEndian: return "UTF-16 LE"
        case .utf16BigEndian: return "UTF-16 BE"
        case .ascii: return "ASCII"
        case .isoLatin1: return "Latin-1 (ISO 8859-1)"
        case .isoLatin2: return "Latin-2 (ISO 8859-2)"
        case .windowsCP1252: return "Windows-1252"
        case .japaneseEUC: return "Japanese (EUC)"
        case .shiftJIS: return "Japanese (Shift JIS)"
        case .macOSRoman: return "Mac Roman"
        default: return description
        }
    }
}
