import Foundation

// MARK: - Markdown Node Types

enum MarkdownNodeType {
    case heading(level: Int)
    case bold
    case italic
    case boldItalic
    case code
    case codeBlock(language: String?)
    case link(url: String, title: String?)
    case image(url: String, alt: String)
    case blockquote
    case unorderedList
    case orderedList
    case horizontalRule
    case strikethrough
    case checkbox(checked: Bool)
}

struct MarkdownNode {
    let type: MarkdownNodeType
    let range: NSRange
    let contentRange: NSRange  // Range without syntax markers
}

// MARK: - Parser

class MarkdownParser {

    // MARK: - Parse to Nodes

    func parse(_ text: String) -> [MarkdownNode] {
        var nodes: [MarkdownNode] = []
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        parseBlockElements(nsString, range: fullRange, into: &nodes)
        parseInlineElements(nsString, range: fullRange, into: &nodes)

        return nodes
    }

    // MARK: - Block Elements

    private func parseBlockElements(_ text: NSString, range: NSRange, into nodes: inout [MarkdownNode]) {
        let string = text.substring(with: range)
        let lines = string.components(separatedBy: "\n")
        var offset = range.location
        var inCodeBlock = false
        var codeBlockStart = 0
        var codeBlockLanguage: String?

        for line in lines {
            let lineRange = NSRange(location: offset, length: (line as NSString).length)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block fences
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    let blockRange = NSRange(location: codeBlockStart, length: offset + (line as NSString).length - codeBlockStart)
                    nodes.append(MarkdownNode(
                        type: .codeBlock(language: codeBlockLanguage),
                        range: blockRange,
                        contentRange: blockRange
                    ))
                    inCodeBlock = false
                } else {
                    // Start of code block
                    inCodeBlock = true
                    codeBlockStart = offset
                    let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = lang.isEmpty ? nil : lang
                }
                offset += (line as NSString).length + 1
                continue
            }

            if inCodeBlock {
                offset += (line as NSString).length + 1
                continue
            }

            // Headings
            if let match = matchHeading(trimmed) {
                let contentStart = offset + match.level + 1 // # + space
                let contentRange = NSRange(location: contentStart, length: max(0, lineRange.length - match.level - 1))
                nodes.append(MarkdownNode(
                    type: .heading(level: match.level),
                    range: lineRange,
                    contentRange: contentRange
                ))
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                nodes.append(MarkdownNode(
                    type: .horizontalRule,
                    range: lineRange,
                    contentRange: lineRange
                ))
            }

            // Blockquote
            if trimmed.hasPrefix("> ") {
                let contentStart = offset + (line.distance(from: line.startIndex, to: line.firstIndex(of: ">")!) + 2)
                let contentLength = max(0, lineRange.length - (contentStart - offset))
                nodes.append(MarkdownNode(
                    type: .blockquote,
                    range: lineRange,
                    contentRange: NSRange(location: contentStart, length: contentLength)
                ))
            }

            // Unordered list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                // Check for checkbox
                if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                    nodes.append(MarkdownNode(type: .checkbox(checked: true), range: lineRange, contentRange: lineRange))
                } else if trimmed.hasPrefix("- [ ] ") {
                    nodes.append(MarkdownNode(type: .checkbox(checked: false), range: lineRange, contentRange: lineRange))
                } else {
                    nodes.append(MarkdownNode(type: .unorderedList, range: lineRange, contentRange: lineRange))
                }
            }

            // Ordered list
            if let _ = trimmed.range(of: #"^\d+\. "#, options: .regularExpression) {
                nodes.append(MarkdownNode(type: .orderedList, range: lineRange, contentRange: lineRange))
            }

            offset += (line as NSString).length + 1
        }
    }

    // MARK: - Inline Elements

    private func parseInlineElements(_ text: NSString, range: NSRange, into nodes: inout [MarkdownNode]) {
        let string = text.substring(with: range)

        // Bold + Italic (***text*** or ___text___)
        findMatches(#"\*\*\*(.+?)\*\*\*"#, in: string, baseOffset: range.location) { fullRange, contentRange in
            nodes.append(MarkdownNode(type: .boldItalic, range: fullRange, contentRange: contentRange))
        }

        // Bold (**text** or __text__)
        findMatches(#"\*\*(.+?)\*\*"#, in: string, baseOffset: range.location) { fullRange, contentRange in
            nodes.append(MarkdownNode(type: .bold, range: fullRange, contentRange: contentRange))
        }

        // Italic (*text* or _text_) — avoid matching ** or __
        findMatches(#"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, in: string, baseOffset: range.location) { fullRange, contentRange in
            nodes.append(MarkdownNode(type: .italic, range: fullRange, contentRange: contentRange))
        }

        // Strikethrough (~~text~~)
        findMatches(#"~~(.+?)~~"#, in: string, baseOffset: range.location) { fullRange, contentRange in
            nodes.append(MarkdownNode(type: .strikethrough, range: fullRange, contentRange: contentRange))
        }

        // Inline code (`code`)
        findMatches(#"`([^`]+)`"#, in: string, baseOffset: range.location) { fullRange, contentRange in
            nodes.append(MarkdownNode(type: .code, range: fullRange, contentRange: contentRange))
        }

        // Links [text](url "title")
        findMatches(#"\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)"#, in: string, baseOffset: range.location, groups: true) { fullRange, contentRange in
            let matchStr = (string as NSString).substring(with: NSRange(
                location: fullRange.location - range.location,
                length: fullRange.length
            ))
            if let urlMatch = matchStr.range(of: #"\(([^)\s]+)"#, options: .regularExpression) {
                var url = String(matchStr[urlMatch]).dropFirst().description
                if url.hasSuffix(")") { url = String(url.dropLast()) }
                nodes.append(MarkdownNode(type: .link(url: url, title: nil), range: fullRange, contentRange: contentRange))
            }
        }

        // Images ![alt](url)
        findMatches(#"!\[([^\]]*)\]\(([^)]+)\)"#, in: string, baseOffset: range.location, groups: true) { fullRange, contentRange in
            let matchStr = (string as NSString).substring(with: NSRange(
                location: fullRange.location - range.location,
                length: fullRange.length
            ))
            if let urlMatch = matchStr.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
                let url = String(matchStr[urlMatch].dropFirst().dropLast())
                let alt = (string as NSString).substring(with: NSRange(
                    location: contentRange.location - range.location,
                    length: contentRange.length
                ))
                nodes.append(MarkdownNode(type: .image(url: url, alt: alt), range: fullRange, contentRange: contentRange))
            }
        }
    }

    // MARK: - Helpers

    private struct HeadingMatch {
        let level: Int
    }

    private func matchHeading(_ line: String) -> HeadingMatch? {
        var level = 0
        for char in line {
            if char == "#" { level += 1 }
            else if char == " " && level > 0 { return HeadingMatch(level: min(level, 6)) }
            else { return nil }
        }
        return nil
    }

    private func findMatches(
        _ pattern: String,
        in string: String,
        baseOffset: Int,
        groups: Bool = false,
        handler: (NSRange, NSRange) -> Void
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let nsString = string as NSString
        let results = regex.matches(in: string, range: NSRange(location: 0, length: nsString.length))

        for result in results {
            let fullRange = NSRange(location: result.range.location + baseOffset, length: result.range.length)
            let contentRange: NSRange
            if result.numberOfRanges > 1 {
                let group1 = result.range(at: 1)
                contentRange = NSRange(location: group1.location + baseOffset, length: group1.length)
            } else {
                contentRange = fullRange
            }
            handler(fullRange, contentRange)
        }
    }

    // MARK: - HTML Generation (for preview)

    func toHTML(_ markdown: String) -> String {
        var html = markdown

        // Code blocks (must be first to avoid inner replacements)
        html = html.replacingOccurrences(
            of: #"```(\w*)\n([\s\S]*?)```"#,
            with: "<pre><code class=\"language-$1\">$2</code></pre>",
            options: .regularExpression
        )

        // Headings
        for level in (1...6).reversed() {
            let prefix = String(repeating: "#", count: level)
            html = html.replacingOccurrences(
                of: "(?m)^\(prefix) (.+)$",
                with: "<h\(level)>$1</h\(level)>",
                options: .regularExpression
            )
        }

        // Horizontal rule
        html = html.replacingOccurrences(of: #"(?m)^(---|\*\*\*|___)$"#, with: "<hr>", options: .regularExpression)

        // Bold + Italic
        html = html.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)

        // Bold
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)

        // Italic
        html = html.replacingOccurrences(of: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, with: "<em>$1</em>", options: .regularExpression)

        // Strikethrough
        html = html.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)

        // Inline code
        html = html.replacingOccurrences(of: #"`([^`]+)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Images
        html = html.replacingOccurrences(of: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)

        // Links
        html = html.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)

        // Blockquotes
        html = html.replacingOccurrences(of: #"(?m)^> (.+)$"#, with: "<blockquote>$1</blockquote>", options: .regularExpression)

        // Unordered lists
        html = html.replacingOccurrences(of: #"(?m)^[*+-] (.+)$"#, with: "<li>$1</li>", options: .regularExpression)

        // Checkboxes
        html = html.replacingOccurrences(of: #"(?m)^- \[x\] (.+)$"#, with: "<li><input type=\"checkbox\" checked disabled> $1</li>", options: [.regularExpression, .caseInsensitive])
        html = html.replacingOccurrences(of: #"(?m)^- \[ \] (.+)$"#, with: "<li><input type=\"checkbox\" disabled> $1</li>", options: .regularExpression)

        // Paragraphs (double newline)
        html = html.replacingOccurrences(of: #"\n\n"#, with: "</p><p>", options: .regularExpression)
        html = "<p>" + html + "</p>"

        return html
    }
}
