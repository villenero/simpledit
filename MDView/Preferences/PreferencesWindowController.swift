import Cocoa

class PreferencesWindowController: NSWindowController {

    static let shared = PreferencesWindowController()

    private let fontSizeSlider = NSSlider()
    private let fontSizeLabel = NSTextField(labelWithString: "13 pt")
    private let tabSizePopup = NSPopUpButton()
    private let wordWrapCheckbox = NSButton(checkboxWithTitle: "Word Wrap", target: nil, action: nil)
    private let mermaidCheckbox = NSButton(checkboxWithTitle: "Enable Mermaid Diagrams", target: nil, action: nil)

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        window.title = "Preferences"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupContent()
        loadFromDefaults()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func setupContent() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 240))

        // Font size — row at y=190
        let fontLabel = NSTextField(labelWithString: "Font Size:")
        fontLabel.frame = NSRect(x: 20, y: 190, width: 80, height: 20)
        contentView.addSubview(fontLabel)

        fontSizeSlider.frame = NSRect(x: 110, y: 190, width: 210, height: 20)
        fontSizeSlider.minValue = 9
        fontSizeSlider.maxValue = 24
        fontSizeSlider.isContinuous = true
        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeChanged(_:))
        contentView.addSubview(fontSizeSlider)

        fontSizeLabel.frame = NSRect(x: 330, y: 190, width: 60, height: 20)
        contentView.addSubview(fontSizeLabel)

        // Tab size — row at y=150
        let tabLabel = NSTextField(labelWithString: "Tab Size:")
        tabLabel.frame = NSRect(x: 20, y: 150, width: 80, height: 20)
        contentView.addSubview(tabLabel)

        tabSizePopup.frame = NSRect(x: 110, y: 148, width: 100, height: 24)
        tabSizePopup.addItems(withTitles: ["2 Spaces", "4 Spaces", "8 Spaces"])
        tabSizePopup.target = self
        tabSizePopup.action = #selector(tabSizeChanged(_:))
        contentView.addSubview(tabSizePopup)

        // Word wrap — row at y=110
        wordWrapCheckbox.frame = NSRect(x: 110, y: 110, width: 200, height: 20)
        wordWrapCheckbox.target = self
        wordWrapCheckbox.action = #selector(wordWrapToggled(_:))
        contentView.addSubview(wordWrapCheckbox)

        // Mermaid diagrams — row at y=70
        mermaidCheckbox.frame = NSRect(x: 110, y: 70, width: 250, height: 20)
        mermaidCheckbox.target = self
        mermaidCheckbox.action = #selector(mermaidToggled(_:))
        contentView.addSubview(mermaidCheckbox)

        // Hint label at bottom
        let hint = NSTextField(labelWithString: "Changes apply immediately.")
        hint.frame = NSRect(x: 20, y: 20, width: 380, height: 16)
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        contentView.addSubview(hint)

        window?.contentView = contentView
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard

        let fontSize = defaults.object(forKey: "FontSize") as? Double ?? 13
        fontSizeSlider.doubleValue = fontSize
        fontSizeLabel.stringValue = "\(Int(fontSize)) pt"

        let tabIndex = defaults.object(forKey: "TabSizeIndex") as? Int ?? 1
        tabSizePopup.selectItem(at: tabIndex)

        let wordWrap = defaults.object(forKey: "WordWrap") as? Bool ?? true
        wordWrapCheckbox.state = wordWrap ? .on : .off

        let mermaid = defaults.bool(forKey: "EnableMermaid")
        mermaidCheckbox.state = mermaid ? .on : .off
    }

    // MARK: - Actions

    @objc private func fontSizeChanged(_ sender: NSSlider) {
        let size = Int(sender.doubleValue)
        fontSizeLabel.stringValue = "\(size) pt"
        UserDefaults.standard.set(sender.doubleValue, forKey: "FontSize")
        NotificationCenter.default.post(name: Notification.Name("PreferencesChanged"), object: nil)
    }

    @objc private func tabSizeChanged(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.indexOfSelectedItem, forKey: "TabSizeIndex")
        NotificationCenter.default.post(name: Notification.Name("PreferencesChanged"), object: nil)
    }

    @objc private func wordWrapToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "WordWrap")
        NotificationCenter.default.post(name: Notification.Name("PreferencesChanged"), object: nil)
    }

    @objc private func mermaidToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "EnableMermaid")
        NotificationCenter.default.post(name: Notification.Name("PreferencesChanged"), object: nil)
    }
}
