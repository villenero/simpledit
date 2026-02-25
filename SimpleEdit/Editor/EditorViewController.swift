import Cocoa
import WebKit

// MARK: - View Mode

enum ViewMode: Int {
    case source = 0
    case styledSource = 1
    case preview = 2
}

class EditorViewController: NSViewController, NSTextStorageDelegate {

    // MARK: - Properties

    private(set) var textView: SimpleTextView!
    private var scrollView: NSScrollView!
    private var statusBar: StatusBarView!
    private var markdownToolbar: MarkdownToolbar!
    private var previewController: MarkdownPreviewController?
    private var splitView: NSSplitView?

    private var markdownTextStorage: MarkdownTextStorage?
    private let markdownParser = MarkdownParser()
    private let markdownStyler = MarkdownStyler()

    private weak var document: Document?
    private var viewMode: ViewMode = .source
    private var wordWrapEnabled: Bool = true
    private var isMarkdownToolbarVisible: Bool = false
    private var isPreviewVisible: Bool = false

    // MARK: - Lifecycle

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = container

        setupMarkdownToolbar()
        setupScrollView()
        setupTextView()
        setupStatusBar()
        layoutSubviews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

        textView = SimpleTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .textColor
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        textView.textStorage?.delegate = self

        scrollView.documentView = textView
    }

    private func setupStatusBar() {
        statusBar = StatusBarView()
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBar)
    }

    private func setupMarkdownToolbar() {
        markdownToolbar = MarkdownToolbar()
        markdownToolbar.translatesAutoresizingMaskIntoConstraints = false
        markdownToolbar.isHidden = true
        view.addSubview(markdownToolbar)
    }

    private func layoutSubviews() {
        NSLayoutConstraint.activate([
            // Markdown toolbar at top
            markdownToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            markdownToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            markdownToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            markdownToolbar.heightAnchor.constraint(equalToConstant: 32),

            // Status bar at bottom
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 22),

            // Scroll view fills the rest
            scrollView.topAnchor.constraint(equalTo: markdownToolbar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
        ])
    }

    // MARK: - Document Loading

    func loadDocument(_ doc: Document) {
        self.document = doc

        guard isViewLoaded else { return }

        textView.string = doc.text

        if doc.isMarkdown {
            viewMode = .styledSource
            switchToMarkdownStorage()
            showMarkdownToolbar(true)
        } else {
            viewMode = .source
            switchToPlainStorage()
            showMarkdownToolbar(false)
        }

        updateStatusBar()
    }

    // MARK: - Markdown Storage Switching

    private func switchToMarkdownStorage() {
        guard markdownTextStorage == nil else {
            applyMarkdownStyling()
            return
        }

        let mdStorage = MarkdownTextStorage(parser: markdownParser, styler: markdownStyler)
        let text = textView.string

        let layoutManager = textView.layoutManager!
        textView.textStorage?.removeLayoutManager(layoutManager)
        mdStorage.addLayoutManager(layoutManager)
        mdStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        mdStorage.delegate = self

        markdownTextStorage = mdStorage
        applyMarkdownStyling()
    }

    private func switchToPlainStorage() {
        guard let mdStorage = markdownTextStorage else { return }

        let text = mdStorage.string
        let layoutManager = textView.layoutManager!

        mdStorage.removeLayoutManager(layoutManager)
        let plainStorage = NSTextStorage(string: text)
        plainStorage.addLayoutManager(layoutManager)
        plainStorage.delegate = self

        markdownTextStorage = nil

        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
    }

    private func applyMarkdownStyling() {
        guard let storage = markdownTextStorage, viewMode == .styledSource else { return }
        storage.applyStyling()
    }

    // MARK: - NSTextStorageDelegate

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        // Only respond to character edits, not attribute-only changes
        guard editedMask.contains(.editedCharacters) else { return }

        // Sync text back to document
        document?.text = textStorage.string

        // Update status bar
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusBar()
        }

        // Update preview if visible
        if isPreviewVisible {
            updatePreviewThrottled()
        }
    }

    // MARK: - Status Bar

    private func updateStatusBar() {
        let text = textView.string
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

        let modeLabel = document?.isMarkdown == true ? "Markdown" : "Plain Text"

        statusBar.update(
            words: wordCount,
            characters: charCount,
            lines: lineCount,
            encoding: encodingName,
            mode: modeLabel
        )
    }

    // MARK: - Preview

    private var previewUpdateWorkItem: DispatchWorkItem?

    private func updatePreviewThrottled() {
        previewUpdateWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.updatePreview()
        }
        previewUpdateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func updatePreview() {
        guard isPreviewVisible, let preview = previewController else { return }
        let html = markdownParser.toHTML(textView.string)
        preview.loadHTML(html)
    }

    private func showPreview() {
        if previewController == nil {
            previewController = MarkdownPreviewController()
        }

        guard let preview = previewController else { return }

        let split = NSSplitView()
        split.isVertical = true
        split.translatesAutoresizingMaskIntoConstraints = false
        split.dividerStyle = .thin

        // Remove scrollView from current parent
        scrollView.removeFromSuperview()

        split.addSubview(scrollView)
        split.addSubview(preview.view)
        view.addSubview(split)

        // Replace scrollView constraints with split constraints
        NSLayoutConstraint.activate([
            split.topAnchor.constraint(equalTo: markdownToolbar.bottomAnchor),
            split.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            split.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
        ])

        self.splitView = split
        isPreviewVisible = true
        updatePreview()
    }

    private func hidePreview() {
        guard let split = splitView else { return }

        scrollView.removeFromSuperview()
        split.removeFromSuperview()
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: markdownToolbar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
        ])

        self.splitView = nil
        isPreviewVisible = false
    }

    // MARK: - Toolbar

    private func showMarkdownToolbar(_ show: Bool) {
        isMarkdownToolbarVisible = show
        markdownToolbar.isHidden = !show
    }

    // MARK: - Menu Actions

    @objc func toggleWordWrap(_ sender: Any?) {
        wordWrapEnabled.toggle()
        if wordWrapEnabled {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.isHorizontallyResizable = false
            scrollView.hasHorizontalScroller = false
        } else {
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.isHorizontallyResizable = true
            scrollView.hasHorizontalScroller = true
        }
    }

    @objc func setTabSize(_ sender: NSMenuItem) {
        textView.tabSize = sender.tag
    }

    @objc func setSourceMode(_ sender: Any?) {
        viewMode = .source
        if markdownTextStorage != nil {
            switchToPlainStorage()
        }
        if isPreviewVisible { hidePreview() }
    }

    @objc func setStyledMode(_ sender: Any?) {
        viewMode = .styledSource
        switchToMarkdownStorage()
        if isPreviewVisible { hidePreview() }
    }

    @objc func togglePreview(_ sender: Any?) {
        if isPreviewVisible {
            hidePreview()
        } else {
            showPreview()
        }
    }

    @objc func toggleMarkdownToolbar(_ sender: Any?) {
        showMarkdownToolbar(!isMarkdownToolbarVisible)
    }
}
