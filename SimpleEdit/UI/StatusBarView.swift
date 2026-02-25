import Cocoa

class StatusBarView: NSView {

    private let label = NSTextField(labelWithString: "")

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
        layer?.backgroundColor = NSColor(white: 0.93, alpha: 1.0).cgColor

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),

            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10),
        ])
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
