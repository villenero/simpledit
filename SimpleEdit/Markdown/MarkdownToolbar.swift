import Cocoa

class MarkdownToolbar: NSView {

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
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
        ])

        // Heading dropdown
        let headingButton = makeButton(title: "H", action: #selector(headingAction(_:)), tooltip: "Heading")
        stackView.addArrangedSubview(headingButton)

        stackView.addArrangedSubview(makeSeparator())

        // Bold
        let boldButton = makeButton(title: "B", action: #selector(boldAction(_:)), tooltip: "Bold (Cmd+B)")
        boldButton.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        stackView.addArrangedSubview(boldButton)

        // Italic
        let italicFont = NSFontManager.shared.convert(NSFont.systemFont(ofSize: 12), toHaveTrait: .italicFontMask)
        let italicButton = makeButton(title: "I", action: #selector(italicAction(_:)), tooltip: "Italic (Cmd+I)")
        italicButton.font = italicFont
        stackView.addArrangedSubview(italicButton)

        // Strikethrough
        let strikeButton = makeButton(title: "S", action: #selector(strikethroughAction(_:)), tooltip: "Strikethrough (Cmd+Shift+X)")
        stackView.addArrangedSubview(strikeButton)

        stackView.addArrangedSubview(makeSeparator())

        // Code
        let codeButton = makeButton(title: "</>", action: #selector(codeAction(_:)), tooltip: "Code (Cmd+E)")
        codeButton.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        stackView.addArrangedSubview(codeButton)

        // Link
        let linkButton = makeButton(title: "Link", action: #selector(linkAction(_:)), tooltip: "Link (Cmd+K)")
        stackView.addArrangedSubview(linkButton)

        stackView.addArrangedSubview(makeSeparator())

        // Unordered list
        let ulButton = makeButton(title: "•", action: #selector(unorderedListAction(_:)), tooltip: "Bullet List")
        stackView.addArrangedSubview(ulButton)

        // Ordered list
        let olButton = makeButton(title: "1.", action: #selector(orderedListAction(_:)), tooltip: "Numbered List")
        stackView.addArrangedSubview(olButton)

        // Blockquote
        let quoteButton = makeButton(title: ">", action: #selector(blockquoteAction(_:)), tooltip: "Blockquote")
        stackView.addArrangedSubview(quoteButton)

        stackView.addArrangedSubview(makeSeparator())

        // Horizontal rule
        let hrButton = makeButton(title: "—", action: #selector(horizontalRuleAction(_:)), tooltip: "Horizontal Rule")
        stackView.addArrangedSubview(hrButton)

        // Checkbox
        let checkButton = makeButton(title: "☐", action: #selector(checkboxAction(_:)), tooltip: "Checkbox")
        stackView.addArrangedSubview(checkButton)

        // Bottom separator
        let bottomSep = NSBox()
        bottomSep.boxType = .separator
        bottomSep.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomSep)
        NSLayoutConstraint.activate([
            bottomSep.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSep.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSep.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    // MARK: - Button Factory

    private func makeButton(title: String, action: Selector, tooltip: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: action)
        button.bezelStyle = .accessoryBarAction
        button.toolTip = tooltip
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        return button
    }

    private func makeSeparator() -> NSView {
        let sep = NSView()
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 4).isActive = true
        return sep
    }

    // MARK: - Helpers

    private func activeTextView() -> SimpleTextView? {
        guard let window = self.window else { return nil }
        return window.firstResponder as? SimpleTextView
    }

    private func wrapSelection(prefix: String, suffix: String) {
        guard let textView = activeTextView() else { return }
        let range = textView.selectedRange()
        let selectedText = (textView.string as NSString).substring(with: range)

        // Toggle: if already wrapped, unwrap
        let fullText = textView.string as NSString
        let beforeStart = max(0, range.location - prefix.count)
        let afterEnd = min(fullText.length, range.location + range.length + suffix.count)

        if beforeStart >= 0, afterEnd <= fullText.length {
            let before = fullText.substring(with: NSRange(location: beforeStart, length: prefix.count))
            let after = fullText.substring(with: NSRange(location: range.location + range.length, length: min(suffix.count, fullText.length - range.location - range.length)))
            if before == prefix, after == suffix {
                // Unwrap
                let unwrapRange = NSRange(location: beforeStart, length: afterEnd - beforeStart)
                textView.insertText(selectedText, replacementRange: unwrapRange)
                return
            }
        }

        let replacement = prefix + selectedText + suffix
        textView.insertText(replacement, replacementRange: range)
    }

    private func prependLine(prefix: String) {
        guard let textView = activeTextView() else { return }
        let range = textView.selectedRange()
        let text = textView.string as NSString
        let lineRange = text.lineRange(for: range)
        let line = text.substring(with: lineRange)

        // Toggle: if line starts with prefix, remove it
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.hasPrefix(prefix) {
            let newLine = line.replacingOccurrences(of: prefix, with: "", options: [], range: line.range(of: prefix))
            textView.insertText(newLine, replacementRange: lineRange)
        } else {
            textView.insertText(prefix + line, replacementRange: lineRange)
        }
    }

    // MARK: - Actions

    @objc func headingAction(_ sender: Any?) {
        prependLine(prefix: "## ")
    }

    @objc func boldAction(_ sender: Any?) {
        wrapSelection(prefix: "**", suffix: "**")
    }

    @objc func italicAction(_ sender: Any?) {
        wrapSelection(prefix: "*", suffix: "*")
    }

    @objc func strikethroughAction(_ sender: Any?) {
        wrapSelection(prefix: "~~", suffix: "~~")
    }

    @objc func codeAction(_ sender: Any?) {
        guard let textView = activeTextView() else { return }
        let range = textView.selectedRange()
        let selectedText = (textView.string as NSString).substring(with: range)

        if selectedText.contains("\n") {
            // Multi-line: use code block
            let replacement = "```\n" + selectedText + "\n```"
            textView.insertText(replacement, replacementRange: range)
        } else {
            wrapSelection(prefix: "`", suffix: "`")
        }
    }

    @objc func linkAction(_ sender: Any?) {
        guard let textView = activeTextView() else { return }
        let range = textView.selectedRange()
        let selectedText = (textView.string as NSString).substring(with: range)

        if selectedText.isEmpty {
            textView.insertText("[link text](url)", replacementRange: range)
        } else {
            textView.insertText("[\(selectedText)](url)", replacementRange: range)
        }
    }

    @objc func unorderedListAction(_ sender: Any?) {
        prependLine(prefix: "- ")
    }

    @objc func orderedListAction(_ sender: Any?) {
        prependLine(prefix: "1. ")
    }

    @objc func blockquoteAction(_ sender: Any?) {
        prependLine(prefix: "> ")
    }

    @objc func horizontalRuleAction(_ sender: Any?) {
        guard let textView = activeTextView() else { return }
        let range = textView.selectedRange()
        textView.insertText("\n---\n", replacementRange: range)
    }

    @objc func checkboxAction(_ sender: Any?) {
        prependLine(prefix: "- [ ] ")
    }
}
