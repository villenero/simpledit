import Cocoa

class StatusBarView: NSView {

    private let label = NSTextField(labelWithString: "")
    private let stylePopUp = NSPopUpButton(frame: .zero, pullsDown: false)

    var onStyleChanged: ((EditorStyle) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = false
        layer?.backgroundColor = NSColor(white: 0.93, alpha: 1.0).cgColor

        // No top separator — the editor above provides its own boundary

        // Style dropdown
        stylePopUp.removeAllItems()
        for (i, style) in EditorStyle.all.enumerated() {
            let item = NSMenuItem(title: style.name, action: nil, keyEquivalent: "\(i + 1)")
            item.keyEquivalentModifierMask = [.command]
            stylePopUp.menu?.addItem(item)
        }
        stylePopUp.font = NSFont.systemFont(ofSize: 11)
        stylePopUp.controlSize = .small
        (stylePopUp.cell as? NSPopUpButtonCell)?.bezelStyle = .inline
        stylePopUp.target = self
        stylePopUp.action = #selector(styleChanged(_:))
        stylePopUp.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stylePopUp)

        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            stylePopUp.centerYAnchor.constraint(equalTo: centerYAnchor),
            stylePopUp.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }

    @objc private func styleChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        let styles = EditorStyle.all
        guard index >= 0, index < styles.count else { return }
        onStyleChanged?(styles[index])
    }

    func selectStyle(at index: Int) {
        guard index >= 0, index < EditorStyle.all.count else { return }
        stylePopUp.selectItem(at: index)
    }

    func update(words: Int, characters: Int, lines: Int, encoding: String, mode: String) {
        label.stringValue = "\(mode)  |  \(lines) lines  |  \(words) words  |  \(characters) chars  |  \(encoding)"
    }

    override func updateLayer() {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            layer?.backgroundColor = NSColor(white: 0.18, alpha: 1.0).cgColor
        } else {
            layer?.backgroundColor = NSColor(white: 0.93, alpha: 1.0).cgColor
        }
    }
}
