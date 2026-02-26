import Cocoa

class StatusBarView: NSView {

    private let styleIcon = NSImageView()
    private let stylePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let editorIcon = NSImageView()
    private let editorPopUp = NSPopUpButton(frame: .zero, pullsDown: true)
    private var editorApps: [(name: String, url: URL, icon: NSImage)] = []

    var onStyleChanged: ((EditorStyle) -> Void)?
    var currentFilePath: String?

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

        // Palette icon for themes
        styleIcon.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "Theme")
        styleIcon.contentTintColor = .secondaryLabelColor
        styleIcon.imageScaling = .scaleProportionallyDown
        styleIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(styleIcon)

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

        // Pencil icon for editors (right side)
        editorIcon.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Open in editor")
        editorIcon.contentTintColor = .secondaryLabelColor
        editorIcon.imageScaling = .scaleProportionallyDown
        editorIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(editorIcon)

        // Editor dropdown (open in...)
        editorPopUp.font = NSFont.systemFont(ofSize: 11)
        editorPopUp.controlSize = .small
        (editorPopUp.cell as? NSPopUpButtonCell)?.bezelStyle = .inline
        editorPopUp.translatesAutoresizingMaskIntoConstraints = false
        editorPopUp.target = self
        editorPopUp.action = #selector(editorSelected(_:))
        addSubview(editorPopUp)
        populateEditors()

        NSLayoutConstraint.activate([
            styleIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            styleIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            styleIcon.widthAnchor.constraint(equalToConstant: 14),
            styleIcon.heightAnchor.constraint(equalToConstant: 14),

            stylePopUp.centerYAnchor.constraint(equalTo: centerYAnchor),
            stylePopUp.leadingAnchor.constraint(equalTo: styleIcon.trailingAnchor, constant: 2),

            editorPopUp.centerYAnchor.constraint(equalTo: centerYAnchor),
            editorPopUp.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            editorIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            editorIcon.trailingAnchor.constraint(equalTo: editorPopUp.leadingAnchor, constant: -2),
            editorIcon.widthAnchor.constraint(equalToConstant: 14),
            editorIcon.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    // MARK: - Editors

    private func populateEditors() {
        editorApps.removeAll()
        editorPopUp.removeAllItems()

        // Title item for pull-down menu
        editorPopUp.addItem(withTitle: "Open in…")

        let bundleIDs = [
            "com.microsoft.VSCode",
            "com.sublimetext.4",
            "com.sublimetext.3",
            "com.github.atom",
            "com.todesktop.230313mzl4w4u92",  // Cursor
            "dev.zed.Zed",
            "com.jetbrains.intellij",
            "com.apple.TextEdit",
            "com.apple.dt.Xcode",
            "com.barebones.bbedit",
            "com.macromates.TextMate",
            "abnerworks.Typora",
            "com.coteditor.CotEditor",
            "com.panic.Nova",
        ]

        for bundleID in bundleIDs {
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { continue }
            let appName = FileManager.default.displayName(atPath: appURL.path)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 16, height: 16)

            editorApps.append((name: appName, url: appURL, icon: icon))

            let item = NSMenuItem(title: appName, action: nil, keyEquivalent: "")
            item.image = icon
            editorPopUp.menu?.addItem(item)
        }

        let hasEditors = !editorApps.isEmpty
        editorPopUp.isHidden = !hasEditors
        editorIcon.isHidden = !hasEditors
    }

    @objc private func editorSelected(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem - 1
        guard index >= 0, index < editorApps.count,
              let path = currentFilePath else { return }

        let appURL = editorApps[index].url
        let fileURL = URL(fileURLWithPath: path)

        NSWorkspace.shared.open(
            [fileURL],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    // MARK: - Style

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
        if let wc = window?.windowController as? MainWindowController {
            wc.updateFileInfo(words: words, characters: characters, lines: lines, encoding: encoding, mode: mode)
        }
    }

    override func updateLayer() {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            layer?.backgroundColor = NSColor(white: 0.18, alpha: 1.0).cgColor
        } else {
            layer?.backgroundColor = NSColor(white: 0.93, alpha: 1.0).cgColor
        }
    }
}
