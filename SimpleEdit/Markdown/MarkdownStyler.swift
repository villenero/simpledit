import Cocoa

class MarkdownStyler {

    var hideMarkers: Bool = false

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

    // Attributes to make markers invisible
    private var hiddenAttrs: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 0.1),
            .foregroundColor: NSColor.clear
        ]
    }

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

                // Apply heading style to content only
                if node.contentRange.length > 0 {
                    storage.addAttributes([
                        .font: font,
                        .foregroundColor: ThemeManager.Colors.heading
                    ], range: node.contentRange)
                }

                // Handle # markers
                let markerRange = NSRange(location: node.range.location, length: level + 1)
                if markerRange.location + markerRange.length <= storage.length {
                    if hideMarkers {
                        storage.addAttributes(hiddenAttrs, range: markerRange)
                    } else {
                        storage.addAttributes([
                            .font: font,
                            .foregroundColor: ThemeManager.Colors.syntaxMarker
                        ], range: markerRange)
                    }
                }

            case .bold:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.bold(),
                    .foregroundColor: ThemeManager.Colors.bold
                ], range: node.contentRange)
                styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .italic:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.italic(),
                    .foregroundColor: ThemeManager.Colors.italic
                ], range: node.contentRange)
                styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .boldItalic:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.boldItalic(),
                    .foregroundColor: ThemeManager.Colors.bold
                ], range: node.contentRange)
                styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .code:
                // Style the content (without backticks)
                storage.addAttributes([
                    .font: ThemeManager.Fonts.code(),
                    .foregroundColor: ThemeManager.Colors.code,
                    .backgroundColor: ThemeManager.Colors.codeBackground
                ], range: node.contentRange)
                styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .codeBlock:
                storage.addAttributes([
                    .font: ThemeManager.Fonts.code(),
                    .foregroundColor: ThemeManager.Colors.code,
                    .backgroundColor: ThemeManager.Colors.codeBackground
                ], range: node.range)
                // Hide the ``` fence lines in view mode
                if hideMarkers {
                    hideFenceLines(storage: storage, range: node.range)
                }

            case .link(let url, _):
                if hideMarkers {
                    // Show only the link text, hide [, ](url)
                    storage.addAttributes([
                        .foregroundColor: ThemeManager.Colors.link,
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .link: url,
                        .cursor: NSCursor.pointingHand
                    ], range: node.contentRange)
                    styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)
                } else {
                    storage.addAttributes([
                        .foregroundColor: ThemeManager.Colors.link,
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .link: url,
                        .cursor: NSCursor.pointingHand
                    ], range: node.range)
                }

            case .image(_, _):
                if hideMarkers {
                    storage.addAttributes([
                        .foregroundColor: ThemeManager.Colors.link,
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ], range: node.contentRange)
                    styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)
                } else {
                    storage.addAttributes([
                        .foregroundColor: ThemeManager.Colors.link,
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ], range: node.range)
                }

            case .blockquote:
                storage.addAttributes([
                    .foregroundColor: ThemeManager.Colors.blockquoteText,
                    .paragraphStyle: blockquoteParagraphStyle
                ], range: node.contentRange)
                // Hide or dim > marker
                let markerRange = NSRange(location: node.range.location, length: min(2, node.range.length))
                if markerRange.location + markerRange.length <= storage.length {
                    if hideMarkers {
                        storage.addAttributes(hiddenAttrs, range: markerRange)
                    } else {
                        storage.addAttribute(.foregroundColor, value: ThemeManager.Colors.syntaxMarker, range: markerRange)
                    }
                }

            case .unorderedList, .orderedList:
                storage.addAttribute(.paragraphStyle, value: listParagraphStyle, range: node.range)

            case .horizontalRule:
                if hideMarkers {
                    storage.addAttributes([
                        .foregroundColor: NSColor.clear,
                        .strikethroughStyle: NSUnderlineStyle.thick.rawValue,
                        .strikethroughColor: ThemeManager.Colors.horizontalRule
                    ], range: node.range)
                } else {
                    storage.addAttributes([
                        .foregroundColor: ThemeManager.Colors.horizontalRule,
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .strikethroughColor: ThemeManager.Colors.horizontalRule
                    ], range: node.range)
                }

            case .strikethrough:
                storage.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: ThemeManager.Colors.strikethrough
                ], range: node.contentRange)
                styleMarkers(storage: storage, fullRange: node.range, contentRange: node.contentRange)

            case .checkbox:
                break
            }
        }

        storage.endEditing()
    }

    private func styleMarkers(storage: NSTextStorage, fullRange: NSRange, contentRange: NSRange) {
        let attrs: [NSAttributedString.Key: Any] = hideMarkers
            ? hiddenAttrs
            : [.foregroundColor: ThemeManager.Colors.syntaxMarker]

        // Before content
        if contentRange.location > fullRange.location {
            let beforeRange = NSRange(
                location: fullRange.location,
                length: contentRange.location - fullRange.location
            )
            if beforeRange.location + beforeRange.length <= storage.length {
                storage.addAttributes(attrs, range: beforeRange)
            }
        }
        // After content
        let afterStart = contentRange.location + contentRange.length
        let afterEnd = fullRange.location + fullRange.length
        if afterStart < afterEnd {
            let afterRange = NSRange(location: afterStart, length: afterEnd - afterStart)
            if afterRange.location + afterRange.length <= storage.length {
                storage.addAttributes(attrs, range: afterRange)
            }
        }
    }

    private func hideFenceLines(storage: NSTextStorage, range: NSRange) {
        let text = storage.string as NSString
        let blockText = text.substring(with: range)
        let lines = blockText.components(separatedBy: "\n")
        guard lines.count >= 2 else { return }

        // Hide first line (```lang)
        let firstLineLength = (lines[0] as NSString).length
        if firstLineLength > 0 {
            let firstLineRange = NSRange(location: range.location, length: firstLineLength)
            storage.addAttributes(hiddenAttrs, range: firstLineRange)
        }

        // Hide last line (```)
        let lastLine = lines[lines.count - 1]
        let lastLineLength = (lastLine as NSString).length
        if lastLineLength > 0 {
            let lastLineStart = range.location + range.length - lastLineLength
            let lastLineRange = NSRange(location: lastLineStart, length: lastLineLength)
            if lastLineRange.location >= range.location {
                storage.addAttributes(hiddenAttrs, range: lastLineRange)
            }
        }
    }
}
