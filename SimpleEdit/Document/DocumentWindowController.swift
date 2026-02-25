import Cocoa

class DocumentWindowController: NSWindowController {

    let editorViewController = EditorViewController()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        window.tabbingMode = .preferred
        window.title = "Untitled"
        window.isReleasedWhenClosed = false

        self.init(window: window)
        window.contentViewController = editorViewController
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        loadDocumentContent()
    }

    override var document: AnyObject? {
        didSet { loadDocumentContent() }
    }

    private func loadDocumentContent() {
        guard let doc = document as? Document else { return }
        editorViewController.loadDocument(doc)
    }
}
