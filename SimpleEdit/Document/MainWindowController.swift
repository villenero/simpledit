import Cocoa

class MainWindowController: NSWindowController, TabBarViewDelegate {

    static let shared = MainWindowController()

    private(set) var documents: [Document] = []
    private(set) var selectedIndex: Int = -1

    private let tabBar = TabBarView()
    private let editorViewController = EditorViewController()
    private let containerView = DragContainerView()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 400, height: 300)
        window.title = "SimpleEdit"
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed

        super.init(window: window)

        setupUI()
        setupDragAndDrop()

        window.setContentSize(NSSize(width: 800, height: 600))
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let window = window else { return }

        let contentFrame = window.contentLayoutRect
        containerView.frame = contentFrame
        containerView.autoresizingMask = [.width, .height]
        window.contentView = containerView

        let tabBarHeight: CGFloat = 38
        tabBar.frame = NSRect(x: 0, y: contentFrame.height - tabBarHeight,
                              width: contentFrame.width, height: tabBarHeight)
        tabBar.autoresizingMask = [.width, .minYMargin]
        tabBar.delegate = self
        containerView.addSubview(tabBar)

        let editorView = editorViewController.view
        editorView.frame = NSRect(x: 0, y: 0,
                                  width: contentFrame.width,
                                  height: contentFrame.height - tabBarHeight)
        editorView.autoresizingMask = [.width, .height]
        containerView.addSubview(editorView)
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
            _ = try? NSDocumentController.shared.openUntitledDocumentAndDisplay(true)
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
            window?.title = "SimpleEdit"
            return
        }
        let doc = documents[selectedIndex]
        window?.title = doc.displayName
        window?.representedURL = doc.fileURL
    }

    // MARK: - TabBarViewDelegate

    func tabBar(_ tabBar: TabBarView, didSelectTabAt index: Int) {
        selectTab(at: index)
    }

    func tabBar(_ tabBar: TabBarView, didCloseTabAt index: Int) {
        closeDocument(at: index)
    }

    // MARK: - Show

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
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
