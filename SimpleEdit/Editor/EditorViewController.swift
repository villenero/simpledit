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
        \(MarkdownPreviewController.previewCSS)
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
