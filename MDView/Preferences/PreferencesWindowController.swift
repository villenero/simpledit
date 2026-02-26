import Cocoa

class PreferencesWindowController: NSWindowController {

    static let shared = PreferencesWindowController()

    private let fontSizeSlider = NSSlider()
    private let tabSizePopup = NSPopUpButton()
    private let wordWrapCheckbox = NSButton(checkboxWithTitle: "Word Wrap", target: nil, action: nil)

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        window.title = "Preferences"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func setupContent() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))

        // Font size
        let fontLabel = NSTextField(labelWithString: "Font Size:")
        fontLabel.frame = NSRect(x: 20, y: 150, width: 80, height: 20)
        contentView.addSubview(fontLabel)

        fontSizeSlider.frame = NSRect(x: 110, y: 150, width: 200, height: 20)
        fontSizeSlider.minValue = 9
        fontSizeSlider.maxValue = 24
        fontSizeSlider.doubleValue = 13
        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeChanged(_:))
        contentView.addSubview(fontSizeSlider)

        let sizeLabel = NSTextField(labelWithString: "13 pt")
        sizeLabel.frame = NSRect(x: 320, y: 150, width: 50, height: 20)
        sizeLabel.tag = 100
        contentView.addSubview(sizeLabel)

        // Tab size
        let tabLabel = NSTextField(labelWithString: "Tab Size:")
        tabLabel.frame = NSRect(x: 20, y: 110, width: 80, height: 20)
        contentView.addSubview(tabLabel)

        tabSizePopup.frame = NSRect(x: 110, y: 108, width: 100, height: 24)
        tabSizePopup.addItems(withTitles: ["2 Spaces", "4 Spaces", "8 Spaces"])
        tabSizePopup.selectItem(at: 1)
        contentView.addSubview(tabSizePopup)

        // Word wrap
        wordWrapCheckbox.frame = NSRect(x: 110, y: 70, width: 200, height: 20)
        wordWrapCheckbox.state = .on
        contentView.addSubview(wordWrapCheckbox)

        window?.contentView = contentView
    }

    @objc private func fontSizeChanged(_ sender: NSSlider) {
        let size = Int(sender.doubleValue)
        if let sizeLabel = window?.contentView?.viewWithTag(100) as? NSTextField {
            sizeLabel.stringValue = "\(size) pt"
        }
    }
}
