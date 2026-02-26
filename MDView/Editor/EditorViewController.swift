import Cocoa
import WebKit

class EditorViewController: NSViewController {

    // MARK: - Properties

    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var webView: WKWebView!
    private var statusBar: StatusBarView!

    private let markdownParser = MarkdownParser()
    private weak var document: Document?
    private var isMarkdownMode: Bool = false
    private var currentStyle: EditorStyle = .light

    // MARK: - Lifecycle

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = container

        setupScrollView()
        setupTextView()
        setupWebView()
        setupStatusBar()
        layoutSubviews()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
    }

    private func setupTextView() {
        let contentSize = scrollView.contentSize

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        layoutManager.allowsNonContiguousLayout = true
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 40, height: 20)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false

        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsMagnification = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isHidden = true
        view.addSubview(webView)
    }

    private func setupStatusBar() {
        statusBar = StatusBarView()
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        statusBar.onStyleChanged = { [weak self] style in
            self?.applyStyle(style)
        }
        view.addSubview(statusBar)
    }

    private func layoutSubviews() {
        NSLayoutConstraint.activate([
            // Status bar at bottom
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 30),

            // Scroll view (plain text)
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),

            // Web view (markdown)
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
        ])
    }

    // MARK: - Document Loading

    func loadDocument(_ doc: Document) {
        self.document = doc

        guard isViewLoaded else { return }

        isMarkdownMode = doc.isMarkdown

        if isMarkdownMode {
            showMarkdownView(doc.text)
        } else {
            showPlainTextView(doc.text)
        }

        updateStatusBar()
    }

    private func showMarkdownView(_ text: String) {
        scrollView.isHidden = true
        webView.isHidden = false

        let html = markdownParser.toHTML(text)
        let fullHTML = wrapInTemplate(html)
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }

    private func showPlainTextView(_ text: String) {
        scrollView.isHidden = false
        webView.isHidden = true

        textView.string = text
        textView.font = currentStyle.font
        textView.textColor = currentStyle.textColor
        textView.backgroundColor = currentStyle.backgroundColor
    }

    // MARK: - Style

    func applyStyle(_ style: EditorStyle) {
        currentStyle = style

        textView.font = style.font
        textView.textColor = style.textColor
        textView.backgroundColor = style.backgroundColor

        if let index = EditorStyle.all.firstIndex(where: { $0.name == style.name }) {
            statusBar.selectStyle(at: index)
        }

        if isMarkdownMode, let text = document?.text {
            let html = markdownParser.toHTML(text)
            let fullHTML = wrapInTemplate(html)
            webView.loadHTMLString(fullHTML, baseURL: nil)
        }
    }

    // MARK: - HTML Template

    private func wrapInTemplate(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        \(currentStyle.markdownCSS)
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    // MARK: - Status Bar

    private func updateStatusBar() {
        let text: String
        if isMarkdownMode {
            text = document?.text ?? ""
        } else {
            text = textView.string
        }

        let wordCount = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let charCount = text.count
        let lineCount = text.components(separatedBy: .newlines).count

        let encodingName: String
        switch document?.encoding {
        case .utf8: encodingName = "UTF-8"
        case .utf16: encodingName = "UTF-16"
        case .utf16LittleEndian: encodingName = "UTF-16 LE"
        case .utf16BigEndian: encodingName = "UTF-16 BE"
        case .isoLatin1: encodingName = "Latin-1"
        default: encodingName = "UTF-8"
        }

        let modeLabel = isMarkdownMode ? "Markdown" : "Plain Text"

        statusBar.update(
            words: wordCount,
            characters: charCount,
            lines: lineCount,
            encoding: encodingName,
            mode: modeLabel
        )
    }

    // MARK: - Outline

    func extractHeadings() -> [OutlineItem] {
        guard let text = document?.text else { return [] }
        var items: [OutlineItem] = []
        let lines = text.components(separatedBy: "\n")
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                inCodeBlock = !inCodeBlock
                continue
            }
            if inCodeBlock { continue }

            var level = 0
            for char in trimmed {
                if char == "#" { level += 1 }
                else if char == " " && level > 0 { break }
                else { level = 0; break }
            }

            if level > 0 && level <= 6 {
                let title = String(trimmed.dropFirst(level + 1))
                if !title.isEmpty {
                    items.append(OutlineItem(title: title, level: level, lineIndex: index))
                }
            }
        }

        return items
    }

    func scrollToLine(_ lineIndex: Int) {
        if isMarkdownMode {
            // In markdown mode, scroll to the heading element in the web view
            let js = """
            (function() {
                var headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
                var idx = \(headingIndexUpTo(lineIndex));
                if (idx >= 0 && idx < headings.length) {
                    headings[idx].scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        } else {
            // In plain text mode, scroll to the line in the text view
            let text = textView.string
            let lines = text.components(separatedBy: "\n")
            var charIndex = 0
            for i in 0..<min(lineIndex, lines.count) {
                charIndex += lines[i].count + 1 // +1 for newline
            }
            let range = NSRange(location: charIndex, length: 0)
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: NSRange(location: charIndex, length: min(lines[lineIndex].count, text.count - charIndex)))
        }
    }

    /// Returns the heading index (among all headings) that corresponds to lineIndex
    private func headingIndexUpTo(_ lineIndex: Int) -> Int {
        guard let text = document?.text else { return 0 }
        let lines = text.components(separatedBy: "\n")
        var headingCount = -1
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock = !inCodeBlock
                continue
            }
            if inCodeBlock { continue }

            var level = 0
            for char in trimmed {
                if char == "#" { level += 1 }
                else if char == " " && level > 0 { break }
                else { level = 0; break }
            }
            if level > 0 && level <= 6 {
                let title = String(trimmed.dropFirst(level + 1))
                if !title.isEmpty {
                    headingCount += 1
                }
            }

            if index == lineIndex { return headingCount }
        }
        return headingCount
    }

    // MARK: - Search

    private var searchMatches: [NSRange] = []
    private var searchCurrentIndex: Int = -1
    private var lastSearchQuery: String = ""

    struct SearchResult {
        let current: Int  // 1-based, 0 if no matches
        let total: Int
    }

    func performSearch(query: String) -> SearchResult {
        lastSearchQuery = query
        searchMatches = []
        searchCurrentIndex = -1

        guard !query.isEmpty else {
            return SearchResult(current: 0, total: 0)
        }

        if isMarkdownMode {
            return performMarkdownSearch(query: query)
        } else {
            return performPlainTextSearch(query: query)
        }
    }

    private func performPlainTextSearch(query: String) -> SearchResult {
        let text = textView.string as NSString
        var searchRange = NSRange(location: 0, length: text.length)

        while searchRange.location < text.length {
            let range = text.range(of: query, options: .caseInsensitive, range: searchRange)
            if range.location == NSNotFound { break }
            searchMatches.append(range)
            searchRange.location = range.location + range.length
            searchRange.length = text.length - searchRange.location
        }

        if !searchMatches.isEmpty {
            searchCurrentIndex = 0
            let range = searchMatches[0]
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }

        return SearchResult(
            current: searchMatches.isEmpty ? 0 : 1,
            total: searchMatches.count
        )
    }

    private func performMarkdownSearch(query: String) -> SearchResult {
        // Count matches in the raw text for the counter
        guard let rawText = document?.text else {
            return SearchResult(current: 0, total: 0)
        }

        let nsText = rawText as NSString
        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let range = nsText.range(of: query, options: .caseInsensitive, range: searchRange)
            if range.location == NSNotFound { break }
            searchMatches.append(range)
            searchRange.location = range.location + range.length
            searchRange.length = nsText.length - searchRange.location
        }

        if !searchMatches.isEmpty {
            searchCurrentIndex = 0
            scrollToMarkdownMatch(query: query, wrap: true)
        }

        return SearchResult(
            current: searchMatches.isEmpty ? 0 : 1,
            total: searchMatches.count
        )
    }

    func searchNext() -> SearchResult {
        guard !searchMatches.isEmpty else {
            return SearchResult(current: 0, total: 0)
        }

        searchCurrentIndex = (searchCurrentIndex + 1) % searchMatches.count

        if isMarkdownMode {
            scrollToMarkdownMatch(query: lastSearchQuery, wrap: searchCurrentIndex == 0)
        } else {
            let range = searchMatches[searchCurrentIndex]
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }

        return SearchResult(
            current: searchCurrentIndex + 1,
            total: searchMatches.count
        )
    }

    private func scrollToMarkdownMatch(query: String, wrap: Bool) {
        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        let js: String
        if wrap {
            js = """
            (function() {
                window.getSelection().removeAllRanges();
                window.find('\(escaped)', false, false, true);
            })();
            """
        } else {
            js = """
            (function() {
                window.find('\(escaped)', false, false, false);
            })();
            """
        }
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func clearSearch() {
        searchMatches = []
        searchCurrentIndex = -1
        lastSearchQuery = ""
        if isMarkdownMode {
            webView.evaluateJavaScript("window.getSelection().removeAllRanges();", completionHandler: nil)
        }
    }

    // MARK: - Menu Actions

    @objc func toggleWordWrap(_ sender: Any?) {
        guard !isMarkdownMode else { return }
        if textView.textContainer?.widthTracksTextView == true {
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.isHorizontallyResizable = true
            scrollView.hasHorizontalScroller = true
        } else {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.isHorizontallyResizable = false
            scrollView.hasHorizontalScroller = false
        }
    }
}
