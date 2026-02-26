import Cocoa

class MainWindowController: NSWindowController, TabBarViewDelegate {

    static let shared = MainWindowController()

    private(set) var documents: [Document] = []
    private(set) var selectedIndex: Int = -1

    private let tabBar = TabBarView()
    private let toolbar = ToolbarView()
    let editorViewController = EditorViewController()
    private let containerView = DragContainerView()
    private var welcomeView: NSView!

    private let outlineView = OutlineView()
    private var isOutlineVisible = false
    private var outlineWidth: CGFloat = 220
    private let tabBarHeight: CGFloat = 38
    private let toolbarHeight: CGFloat = 30

    private init() {
        let window = MDViewWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 400, height: 300)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed

        super.init(window: window)

        setupUI()
        setupWelcomeView()
        setupDragAndDrop()
        showWelcomeState()

        window.setContentSize(NSSize(width: 800, height: 600))
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Prevent NSDocument from overriding our window title and representedURL
    override func synchronizeWindowTitleWithDocumentName() { /* no-op */ }

    // MARK: - UI Setup

    private func setupUI() {
        guard let window = window else { return }

        // Use full window bounds (includes titlebar area thanks to fullSizeContentView)
        let fullFrame = window.contentView?.bounds ?? window.contentLayoutRect
        containerView.frame = fullFrame
        containerView.autoresizingMask = [.width, .height]
        window.contentView = containerView

        // Tab bar at the very top — same row as traffic lights (Chrome-style)
        // 78px left margin to clear the traffic light buttons
        tabBar.frame = NSRect(x: 78, y: fullFrame.height - tabBarHeight,
                              width: fullFrame.width - 78, height: tabBarHeight)
        tabBar.autoresizingMask = [.width, .minYMargin]
        tabBar.delegate = self
        containerView.addSubview(tabBar)

        // Register tab bar with the window for event forwarding
        (window as? MDViewWindow)?.tabBarView = tabBar

        // Content starts below the safe area (below titlebar)
        let safeTop = window.contentLayoutRect.height

        // Toolbar below the titlebar area (outline + search)
        let toolbarY = safeTop - toolbarHeight
        toolbar.frame = NSRect(x: 0, y: toolbarY,
                               width: fullFrame.width, height: toolbarHeight)
        toolbar.autoresizingMask = [.width, .minYMargin]
        toolbar.parentTabBar = tabBar
        toolbar.tabBarDelegate = self
        containerView.addSubview(toolbar)

        // Editor fills remaining space
        let editorView = editorViewController.view
        editorView.frame = NSRect(x: 0, y: 0,
                                  width: fullFrame.width,
                                  height: toolbarY)
        editorView.autoresizingMask = [.width, .height]
        containerView.addSubview(editorView)

        // Outline sidebar (hidden initially)
        outlineView.frame = NSRect(x: -outlineWidth, y: 0,
                                   width: outlineWidth,
                                   height: toolbarY)
        outlineView.autoresizingMask = [.height, .maxXMargin]
        containerView.addSubview(outlineView)

        outlineView.onItemSelected = { [weak self] item in
            self?.editorViewController.scrollToLine(item.lineIndex)
        }

        outlineView.onResize = { [weak self] newWidth in
            self?.resizeOutline(to: newWidth)
        }
    }

    private func setupWelcomeView() {
        welcomeView = PassthroughView()
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(welcomeView)

        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        if let iconURL = Bundle.module.url(forResource: "icon", withExtension: "png"),
           let icon = NSImage(contentsOf: iconURL) {
            iconView.image = icon
        }
        welcomeView.addSubview(iconView)

        let label = NSTextField(labelWithString: "Drop a file. Start reading.")
        label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .tertiaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(label)

        let subtitleLabel = NSTextField(labelWithString: ".md  .txt  .markdown")
        subtitleLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .quaternaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            welcomeView.topAnchor.constraint(equalTo: containerView.topAnchor),
            welcomeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            welcomeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            welcomeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            iconView.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: welcomeView.centerYAnchor, constant: -40),
            iconView.widthAnchor.constraint(equalToConstant: 128),
            iconView.heightAnchor.constraint(equalToConstant: 128),

            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),
        ])
    }

    private func showWelcomeState() {
        welcomeView.isHidden = false
        tabBar.isHidden = true
        toolbar.isHidden = true
        editorViewController.view.isHidden = true
        editorViewController.updateFilePath(nil)
    }

    private func showEditorState() {
        welcomeView.isHidden = true
        tabBar.isHidden = false
        toolbar.isHidden = false
        editorViewController.view.isHidden = false
    }

    // MARK: - Drag & Drop

    private func setupDragAndDrop() {
        containerView.registerForDraggedTypes([.fileURL])
    }

    // MARK: - Document Management

    func openDocument(_ doc: Document) {
        // If already open, just select it
        if let existingIndex = documents.firstIndex(where: { $0 === doc }) {
            selectTab(at: existingIndex)
            return
        }

        documents.append(doc)
        showEditorState()
        selectTab(at: documents.count - 1)
    }

    func closeDocument(at index: Int) {
        guard index >= 0, index < documents.count else { return }

        let closedDoc = documents[index]
        let currentDoc = (selectedIndex >= 0 && selectedIndex < documents.count) ? documents[selectedIndex] : nil
        documents.remove(at: index)
        closedDoc.removeWindowController(self)
        closedDoc.close()

        if documents.isEmpty {
            selectedIndex = -1
            updateTabBar()
            showWelcomeState()
            return
        }

        if closedDoc === currentDoc {
            // Closed the active tab — need to load a new one
            let newIndex = min(index, documents.count - 1)
            selectedIndex = newIndex
            editorViewController.loadDocument(documents[newIndex])
        } else {
            // Active document didn't change, just fix the index
            selectedIndex = documents.firstIndex(where: { $0 === currentDoc }) ?? 0
        }
        updateTabBar()
        updateWindowTitle()
    }

    func selectTab(at index: Int) {
        guard index >= 0, index < documents.count else { return }
        guard index != selectedIndex else { return }
        selectedIndex = index
        editorViewController.loadDocument(documents[index])
        updateTabBar()
        updateWindowTitle()
        if isOutlineVisible { updateOutline() }
        window?.makeKeyAndOrderFront(nil)
    }

    private func updateTabBar() {
        let items = documents.enumerated().map { (i, doc) in
            TabItem(
                title: doc.displayName,
                isSelected: i == selectedIndex
            )
        }
        tabBar.update(tabs: items)
    }

    private func updateWindowTitle() {
        guard selectedIndex >= 0, selectedIndex < documents.count else {
            editorViewController.updateFilePath(nil)
            return
        }
        let doc = documents[selectedIndex]
        editorViewController.updateFilePath(doc.fileURL?.path)
    }

    // MARK: - Outline

    private func toggleOutline() {
        let contentFrame = containerView.bounds
        let editorView = editorViewController.view
        let bodyHeight = contentFrame.height - toolbarHeight

        isOutlineVisible.toggle()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            if isOutlineVisible {
                outlineView.animator().frame = NSRect(
                    x: 0, y: 0,
                    width: outlineWidth,
                    height: bodyHeight)
                editorView.animator().frame = NSRect(
                    x: outlineWidth, y: 0,
                    width: contentFrame.width - outlineWidth,
                    height: bodyHeight)
            } else {
                outlineView.animator().frame = NSRect(
                    x: -outlineWidth, y: 0,
                    width: outlineWidth,
                    height: bodyHeight)
                editorView.animator().frame = NSRect(
                    x: 0, y: 0,
                    width: contentFrame.width,
                    height: bodyHeight)
            }
        }

        if isOutlineVisible {
            updateOutline()
        }
    }

    private func resizeOutline(to newWidth: CGFloat) {
        guard isOutlineVisible else { return }
        let contentFrame = containerView.bounds
        let editorView = editorViewController.view
        let bodyHeight = contentFrame.height - toolbarHeight

        outlineWidth = newWidth
        outlineView.frame = NSRect(
            x: 0, y: 0,
            width: outlineWidth,
            height: bodyHeight)
        editorView.frame = NSRect(
            x: outlineWidth, y: 0,
            width: contentFrame.width - outlineWidth,
            height: bodyHeight)
    }

    private func updateOutline() {
        let items = editorViewController.extractHeadings()
        outlineView.update(items: items)
    }

    // MARK: - TabBarViewDelegate

    func tabBar(_ tabBar: TabBarView, didSelectTabAt index: Int) {
        selectTab(at: index)
    }

    func tabBar(_ tabBar: TabBarView, didCloseTabAt index: Int) {
        closeDocument(at: index)
    }

    func tabBarDidToggleOutline(_ tabBar: TabBarView) {
        toggleOutline()
    }

    func tabBar(_ tabBar: TabBarView, didSearch query: String) {
        let result = editorViewController.performSearch(query: query)
        toolbar.updateSearchCount(current: result.current, total: result.total)
    }

    func tabBarDidSearchNext(_ tabBar: TabBarView) {
        let result = editorViewController.searchNext()
        toolbar.updateSearchCount(current: result.current, total: result.total)
    }

    func tabBarDidEndSearch(_ tabBar: TabBarView) {
        editorViewController.clearSearch()
    }

    // MARK: - Find

    @objc func focusSearch(_ sender: Any?) {
        toolbar.focusSearchField()
    }

    // MARK: - Show

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Passthrough View (lets drags reach the container underneath)

private class PassthroughView: NSView {
    override func hitTest(_ aPoint: NSPoint) -> NSView? {
        return nil
    }
}

// MARK: - Window (Chrome-style titlebar tabs)

private class MDViewWindow: NSWindow {
    weak var tabBarView: TabBarView?

    override var representedURL: URL? {
        get { nil }
        set { }
    }
    override var representedFilename: String {
        get { "" }
        set { }
    }
    override func setTitleWithRepresentedFilename(_ filename: String) { }

    // Forward mouse events in the titlebar area to the tab bar
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown,
           let tabBar = tabBarView, !tabBar.isHidden {
            let pointInTabBar = tabBar.convert(event.locationInWindow, from: nil)
            if tabBar.bounds.contains(pointInTabBar),
               let target = tabBar.hitTest(pointInTabBar) {
                target.mouseDown(with: event)
                return
            }
        }
        super.sendEvent(event)
    }
}

// MARK: - Drag Container View

private class DragContainerView: NSView {

    private static let validExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "txt", "text"]

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasValidFiles(sender) else { return [] }
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = fileURLs(from: sender) else { return false }
        let validURLs = urls.filter { Self.validExtensions.contains($0.pathExtension.lowercased()) }
        guard !validURLs.isEmpty else { return false }

        for url in validURLs {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
        }
        return true
    }

    private func hasValidFiles(_ info: NSDraggingInfo) -> Bool {
        guard let urls = fileURLs(from: info) else { return false }
        return urls.contains { Self.validExtensions.contains($0.pathExtension.lowercased()) }
    }

    private func fileURLs(from info: NSDraggingInfo) -> [URL]? {
        info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL]
    }
}
