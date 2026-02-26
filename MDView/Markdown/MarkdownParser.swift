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
    case table(MarkdownTable)
}

struct MarkdownNode {
    let type: MarkdownNodeType
    let range: NSRange
    let contentRange: NSRange  // Range without syntax markers
}

// MARK: - Table Structures

struct MarkdownTable {
    let columns: Int
    let headerCells: [MarkdownTableCell]
    let separatorRange: NSRange
    let rows: [[MarkdownTableCell]]  // data rows (excluding header and separator)
}

struct MarkdownTableCell {
    let range: NSRange       // Range of cell content text (trimmed, without |)
    let row: Int             // 0 = header, 1+ = data rows
    let column: Int
}

// MARK: - Parser

class MarkdownParser {

    // MARK: - Parse to Nodes

    func parse(_ text: String) -> [MarkdownNode] {
        var nodes: [MarkdownNode] = []
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        parseBlockElements(nsString, range: fullRange, into: &nodes)

        // Collect code block and table separator ranges to exclude from inline parsing
        // (Table cell content IS parsed for inline elements like bold, italic, etc.)
        let excludedRanges = nodes.compactMap { node -> NSRange? in
            switch node.type {
            case .codeBlock: return node.range
            case .table(let table): return table.separatorRange
            default: return nil
            }
        }

        // Parse inline elements only outside code blocks and tables
        let inlineRanges = subtractRanges(from: fullRange, excluding: excludedRanges)
        for range in inlineRanges {
            parseInlineElements(nsString, range: range, into: &nodes)
        }

        return nodes
    }

    private func subtractRanges(from full: NSRange, excluding: [NSRange]) -> [NSRange] {
        guard !excluding.isEmpty else { return [full] }

        let sorted = excluding.sorted { $0.location < $1.location }
        var ranges: [NSRange] = []
        var current = full.location

        for excluded in sorted {
            if excluded.location > current {
                ranges.append(NSRange(location: current, length: excluded.location - current))
            }
            current = max(current, excluded.location + excluded.length)
        }

        let fullEnd = full.location + full.length
        if current < fullEnd {
            ranges.append(NSRange(location: current, length: fullEnd - current))
        }

        return ranges
    }

    // MARK: - Block Elements

    private func parseBlockElements(_ text: NSString, range: NSRange, into nodes: inout [MarkdownNode]) {
        let string = text.substring(with: range)
        let lines = string.components(separatedBy: "\n")
        var offset = range.location
        var inCodeBlock = false
        var codeBlockStart = 0
        var codeBlockLanguage: String?

        // First pass: collect table line groups (to skip them in the main loop)
        var tableRanges: [NSRange] = []
        var tempOffset = range.location
        var tableStartIdx: Int? = nil
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isTableLine = trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count > 1
            if isTableLine {
                if tableStartIdx == nil { tableStartIdx = idx }
            } else {
                if let start = tableStartIdx, idx - start >= 3 {
                    // We had a table block — check it has a separator row
                    let sepLine = lines[start + 1].trimmingCharacters(in: .whitespaces)
                    if isSeparatorRow(sepLine) {
                        let tableStart = lineOffset(lines: lines, index: start, base: range.location)
                        let tableEnd = lineOffset(lines: lines, index: idx - 1, base: range.location) + (lines[idx - 1] as NSString).length
                        tableRanges.append(NSRange(location: tableStart, length: tableEnd - tableStart))
                    }
                }
                tableStartIdx = nil
            }
            tempOffset += (line as NSString).length + 1
        }
        // Handle table at end of text
        if let start = tableStartIdx, lines.count - start >= 3 {
            let sepLine = lines[start + 1].trimmingCharacters(in: .whitespaces)
            if isSeparatorRow(sepLine) {
                let tableStart = lineOffset(lines: lines, index: start, base: range.location)
                let lastIdx = lines.count - 1
                let tableEnd = lineOffset(lines: lines, index: lastIdx, base: range.location) + (lines[lastIdx] as NSString).length
                tableRanges.append(NSRange(location: tableStart, length: tableEnd - tableStart))
            }
        }

        // Parse tables
        for tableRange in tableRanges {
            parseTable(text, range: tableRange, allLines: lines, base: range.location, into: &nodes)
        }

        // Main loop for other block elements
        for (_, line) in lines.enumerated() {
            let lineRange = NSRange(location: offset, length: (line as NSString).length)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip lines inside tables
            if tableRanges.contains(where: { lineRange.location >= $0.location && lineRange.location + lineRange.length <= $0.location + $0.length }) {
                offset += (line as NSString).length + 1
                continue
            }

            // Code block fences
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    let blockRange = NSRange(location: codeBlockStart, length: offset + (line as NSString).length - codeBlockStart)
                    nodes.append(MarkdownNode(
                        type: .codeBlock(language: codeBlockLanguage),
                        range: blockRange,
                        contentRange: blockRange
                    ))
                    inCodeBlock = false
                } else {
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
                let contentStart = offset + match.level + 1
                let contentRange = NSRange(location: contentStart, length: max(0, lineRange.length - match.level - 1))
                nodes.append(MarkdownNode(
                    type: .heading(level: match.level),
                    range: lineRange,
                    contentRange: contentRange
                ))
            }

            // Horizontal rule (but not table separator)
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

    // MARK: - Table Parsing

    private func lineOffset(lines: [String], index: Int, base: Int) -> Int {
        var offset = base
        for i in 0..<index {
            offset += (lines[i] as NSString).length + 1
        }
        return offset
    }

    private func isSeparatorRow(_ line: String) -> Bool {
        let cells = line.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let cleaned = cell.replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ":", with: "")
            return cleaned.isEmpty
        }
    }

    private func parseCellRanges(line: String, lineOffset: Int) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsLine = line as NSString
        // Find positions of all |
        var pipePositions: [Int] = []
        for charIdx in 0..<nsLine.length {
            if nsLine.character(at: charIdx) == Character("|").asciiValue! {
                pipePositions.append(charIdx)
            }
        }
        guard pipePositions.count >= 2 else { return ranges }
        // Each cell is between consecutive pipes
        for pIdx in 0..<(pipePositions.count - 1) {
            let start = pipePositions[pIdx] + 1
            let end = pipePositions[pIdx + 1]
            if start < end {
                // Trim whitespace from cell content
                let cellStr = nsLine.substring(with: NSRange(location: start, length: end - start))
                let trimmed = cellStr as NSString
                var contentStart = 0
                var contentEnd = trimmed.length
                while contentStart < contentEnd && (trimmed.character(at: contentStart) == Character(" ").asciiValue!) {
                    contentStart += 1
                }
                while contentEnd > contentStart && (trimmed.character(at: contentEnd - 1) == Character(" ").asciiValue!) {
                    contentEnd -= 1
                }
                ranges.append(NSRange(location: lineOffset + start + contentStart, length: contentEnd - contentStart))
            } else {
                ranges.append(NSRange(location: lineOffset + start, length: 0))
            }
        }
        return ranges
    }

    private func parseTable(_ text: NSString, range: NSRange, allLines: [String], base: Int, into nodes: inout [MarkdownNode]) {
        let tableStr = text.substring(with: range)
        let tableLines = tableStr.components(separatedBy: "\n")
        guard tableLines.count >= 3 else { return }

        // Header row
        let headerOffset = range.location
        let headerCellRanges = parseCellRanges(line: tableLines[0], lineOffset: headerOffset)
        let columnCount = headerCellRanges.count
        guard columnCount > 0 else { return }

        let headerCells = headerCellRanges.enumerated().map { (col, cellRange) in
            MarkdownTableCell(range: cellRange, row: 0, column: col)
        }

        // Separator row
        let sepOffset = headerOffset + (tableLines[0] as NSString).length + 1
        let sepRange = NSRange(location: sepOffset, length: (tableLines[1] as NSString).length)

        // Data rows
        var dataRows: [[MarkdownTableCell]] = []
        var rowOffset = sepOffset + (tableLines[1] as NSString).length + 1
        for rowIdx in 2..<tableLines.count {
            let line = tableLines[rowIdx]
            let cellRanges = parseCellRanges(line: line, lineOffset: rowOffset)
            let cells = cellRanges.enumerated().map { (col, cellRange) in
                MarkdownTableCell(range: cellRange, row: rowIdx - 1, column: col)
            }
            dataRows.append(cells)
            rowOffset += (line as NSString).length + 1
        }

        let table = MarkdownTable(
            columns: columnCount,
            headerCells: headerCells,
            separatorRange: sepRange,
            rows: dataRows
        )

        nodes.append(MarkdownNode(
            type: .table(table),
            range: range,
            contentRange: range
        ))
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

        // Tables (must be before paragraphs and other block elements)
        html = convertTables(html)

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

    // MARK: - Table HTML Conversion

    private func convertTables(_ html: String) -> String {
        let lines = html.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            // Check if this starts a table: line with |, next line is separator
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count > 1,
               i + 2 < lines.count {
                let sepLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if isSeparatorRow(sepLine) {
                    // Parse header
                    let headerCells = parseHTMLTableCells(trimmed)
                    var tableHTML = "<table>\n<thead>\n<tr>"
                    for cell in headerCells {
                        tableHTML += "<th>\(cell)</th>"
                    }
                    tableHTML += "</tr>\n</thead>\n<tbody>"

                    // Skip header and separator
                    i += 2

                    // Parse data rows
                    while i < lines.count {
                        let rowTrimmed = lines[i].trimmingCharacters(in: .whitespaces)
                        guard rowTrimmed.hasPrefix("|") && rowTrimmed.hasSuffix("|") && rowTrimmed.count > 1 else { break }
                        let cells = parseHTMLTableCells(rowTrimmed)
                        tableHTML += "\n<tr>"
                        for cell in cells {
                            tableHTML += "<td>\(cell)</td>"
                        }
                        tableHTML += "</tr>"
                        i += 1
                    }

                    tableHTML += "\n</tbody>\n</table>"
                    result.append(tableHTML)
                    continue
                }
            }

            result.append(lines[i])
            i += 1
        }

        return result.joined(separator: "\n")
    }

    private func parseHTMLTableCells(_ line: String) -> [String] {
        let inner = line.trimmingCharacters(in: .whitespaces)
        // Remove leading and trailing |
        let stripped = String(inner.dropFirst().dropLast())
        return stripped.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
