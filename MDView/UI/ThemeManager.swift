import Cocoa

struct ThemeManager {

    struct Colors {
        static var editorBackground: NSColor { .textBackgroundColor }
        static var editorText: NSColor { .textColor }
        static var heading: NSColor { .labelColor }
        static var bold: NSColor { .labelColor }
        static var italic: NSColor { .labelColor }
        static var code: NSColor { NSColor(named: "CodeColor") ?? .systemOrange }
        static var codeBackground: NSColor {
            NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor.white.withAlphaComponent(0.06)
                : NSColor.black.withAlphaComponent(0.04)
        }
        static var link: NSColor { .linkColor }
        static var blockquoteBorder: NSColor { .systemBlue.withAlphaComponent(0.5) }
        static var blockquoteText: NSColor { .secondaryLabelColor }
        static var syntaxMarker: NSColor { .tertiaryLabelColor }
        static var horizontalRule: NSColor { .separatorColor }
        static var strikethrough: NSColor { .secondaryLabelColor }
    }

    struct Fonts {
        static let defaultSize: CGFloat = 13

        static func body(size: CGFloat = defaultSize) -> NSFont {
            .monospacedSystemFont(ofSize: size, weight: .regular)
        }

        static func heading1() -> NSFont {
            .systemFont(ofSize: 24, weight: .bold)
        }

        static func heading2() -> NSFont {
            .systemFont(ofSize: 20, weight: .bold)
        }

        static func heading3() -> NSFont {
            .systemFont(ofSize: 17, weight: .semibold)
        }

        static func heading4() -> NSFont {
            .systemFont(ofSize: 15, weight: .semibold)
        }

        static func heading5() -> NSFont {
            .systemFont(ofSize: 13, weight: .semibold)
        }

        static func heading6() -> NSFont {
            .systemFont(ofSize: 12, weight: .semibold)
        }

        static func code(size: CGFloat = defaultSize) -> NSFont {
            .monospacedSystemFont(ofSize: size, weight: .regular)
        }

        static func bold(size: CGFloat = defaultSize) -> NSFont {
            .monospacedSystemFont(ofSize: size, weight: .bold)
        }

        static func italic(size: CGFloat = defaultSize) -> NSFont {
            let descriptor = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
                .fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        }

        static func boldItalic(size: CGFloat = defaultSize) -> NSFont {
            let descriptor = NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
                .fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .bold)
        }
    }
}
