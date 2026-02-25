import Cocoa

class MarkdownStyler {

    // Cache paragraph styles to avoid recreating them
    private let blockquoteParagraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.headIndent = 20
        style.firstLineHeadIndent = 20
        return style
    }()

    private let listParagraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.headIndent = 24
        style.firstLineHeadIndent = 8
        return style
    }()

    func apply(nodes: [MarkdownNode], to storage: NSTextStorage) {
        storage.beginEditing()

        for node in nodes {
            // Safety check
            guard node.range.location + node.range.length <= storage.length else { continue }

            switch node.type {
            case .heading(let level):
                let font: NSFont
                switch level {
                case 1: font = ThemeManager.Fonts.heading1()
                case 2: font = ThemeManager.Fonts.heading2()
                case 3: font = ThemeManager.Fonts.heading3()
                case 4: font = ThemeManager.Fonts.heading4()
                case 5: font = ThemeManager.Fonts.heading5()
                default: font = ThemeManager.Fonts.heading6()
                }
                storage.addAttributes([
                    .font: font,
                    .foregroundColor: ThemeManager.Colors.heading
                ], range: node.range)

                // Dim the # markers
                let markerRange = NSRange(location: node.range.location, length: level + 1)
                if markerRange.location + markerRange.length <= storage.length {
                    storage.addAttribute(.foregroundColor, value: ThemeManager.Colors.syntaxMarker, range: markerRange)
                }

            case .bold:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.bold(),
                    .foregroundColor: ThemeManager.Colors.bold
                ], range: node.contentRange)
                // Dim markers **
                dimMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .italic:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.italic(),
                    .foregroundColor: ThemeManager.Colors.italic
                ], range: node.contentRange)
                dimMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .boldItalic:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.boldItalic(),
                    .foregroundColor: ThemeManager.Colors.bold
                ], range: node.contentRange)
                dimMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .code:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.code(),
                    .foregroundColor: ThemeManager.Colors.code,
                    .backgroundColor: ThemeManager.Colors.codeBackground
                ], range: node.range)
                // Dim backticks
                dimMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .codeBlock:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.code(),
                    .foregroundColor: ThemeManager.Colors.code,
                    .backgroundColor: ThemeManager.Colors.codeBackground
                ], range: node.range)

            case .link(let url, _):
                storage.addAttributes([
                    .foregroundColor: ThemeManager.Colors.link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: url,
                    .cursor: NSCursor.pointingHand
                ], range: node.range)

            case .image(_, _):
                storage.addAttributes([
                    .foregroundColor: ThemeManager.Colors.link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: node.range)

            case .blockquote:
                storage.addAttributes([
                    .foregroundColor: ThemeManager.Colors.blockquoteText,
                    .paragraphStyle: blockquoteParagraphStyle
                ], range: node.range)
                // Dim > marker
                let markerRange = NSRange(location: node.range.location, length: min(2, node.range.length))
                storage.addAttribute(.foregroundColor, value: ThemeManager.Colors.syntaxMarker, range: markerRange)

            case .unorderedList, .orderedList:
                storage.addAttribute(.paragraphStyle, value: listParagraphStyle, range: node.range)

            case .horizontalRule:
                storage.addAttributes([
                    .foregroundColor: ThemeManager.Colors.horizontalRule,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: ThemeManager.Colors.horizontalRule
                ], range: node.range)

            case .strikethrough:
                storage.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: ThemeManager.Colors.strikethrough
                ], range: node.contentRange)
                dimMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .checkbox:
                break
            }
        }

        storage.endEditing()
    }

    private func dimMarkers(storage: NSTextStorage, fullRange: NSRange, contentRange: NSRange) {
        // Before content
        if contentRange.location > fullRange.location {
            let beforeRange = NSRange(
                location: fullRange.location,
                length: contentRange.location - fullRange.location
            )
            if beforeRange.location + beforeRange.length <= storage.length {
                storage.addAttribute(.foregroundColor, value: ThemeManager.Colors.syntaxMarker, range: beforeRange)
            }
        }
        // After content
        let afterStart = contentRange.location + contentRange.length
        let afterEnd = fullRange.location + fullRange.length
        if afterStart < afterEnd {
            let afterRange = NSRange(location: afterStart, length: afterEnd - afterStart)
            if afterRange.location + afterRange.length <= storage.length {
                storage.addAttribute(.foregroundColor, value: ThemeManager.Colors.syntaxMarker, range: afterRange)
            }
        }
    }
}
