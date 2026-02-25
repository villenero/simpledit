import Cocoa

class DocumentWindowController: NSWindowController, NSToolbarDelegate {

    let editorViewController = EditorViewController()
    private var editButton: NSButton!

    private static let toolbarIdentifier = NSToolbar.Identifier("SimpleEditToolbar")
    private static let editButtonItemIdentifier = NSToolbarItem.Identifier("EditToggle")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        window.tabbingMode = .preferred
        window.title = "Untitled"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible

        self.init(window: window)
        window.contentViewController = editorViewController

        setupToolbar()
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
        updateEditButton()
    }

    // MARK: - Toolbar

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: Self.toolbarIdentifier)
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = false
        window?.toolbar = toolbar
    }

    func updateEditButton() {
        guard let button = editButton else { return }
        if editorViewController.isEditing {
            button.title = "Done"
            button.contentTintColor = .systemBlue
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Done editing")
        } else {
            button.title = "Edit"
            button.contentTintColor = .secondaryLabelColor
            button.image = NSImage(systemSymbolName: "pencil.circle", accessibilityDescription: "Edit document")
        }
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == Self.editButtonItemIdentifier else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)

        editButton = NSButton(title: "Edit", target: editorViewController, action: #selector(EditorViewController.toggleEditMode(_:)))
        editButton.bezelStyle = .accessoryBarAction
        editButton.image = NSImage(systemSymbolName: "pencil.circle", accessibilityDescription: "Edit document")
        editButton.imagePosition = .imageLeading
        editButton.contentTintColor = .secondaryLabelColor
        editButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true

        item.view = editButton
        item.label = "Edit"
        item.toolTip = "Toggle edit mode"

        return item
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.editButtonItemIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.editButtonItemIdentifier, .flexibleSpace, .space]
    }
}
