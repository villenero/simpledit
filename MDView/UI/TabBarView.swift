import Cocoa

protocol TabBarViewDelegate: AnyObject {
    func tabBar(_ tabBar: TabBarView, didSelectTabAt index: Int)
    func tabBar(_ tabBar: TabBarView, didCloseTabAt index: Int)
    func tabBarDidToggleOutline(_ tabBar: TabBarView)
    func tabBar(_ tabBar: TabBarView, didSearch query: String)
    func tabBarDidSearchNext(_ tabBar: TabBarView)
    func tabBarDidEndSearch(_ tabBar: TabBarView)
    func tabBarDidReload(_ tabBar: TabBarView)
}

struct TabItem {
    let title: String
    let isSelected: Bool
    let isMarkdown: Bool
}

class TabBarView: NSView {

    weak var delegate: TabBarViewDelegate?

    private var tabs: [TabItem] = []
    private var tabButtons: [NSView] = []
    private let stackView = NSStackView()
    private let scrollView = NSScrollView()

    override var mouseDownCanMoveWindow: Bool { false }

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
        layer?.backgroundColor = NSColor(white: 0.90, alpha: 1.0).cgColor

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stackView.orientation = .horizontal
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.edgeInsets = NSEdgeInsets(top: 6, left: 4, bottom: 0, right: 4)
        scrollView.documentView = stackView

        NSLayoutConstraint.activate([
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
    }

    func update(tabs: [TabItem]) {
        self.tabs = tabs
        rebuildTabs()
    }

    private var tabWidthConstraints: [NSLayoutConstraint] = []
    private let maxTabWidth: CGFloat = 150
    private let minTabWidth: CGFloat = 40

    private func rebuildTabs() {
        for view in tabButtons {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        tabButtons.removeAll()
        tabWidthConstraints.removeAll()

        for (index, tab) in tabs.enumerated() {
            let tabView = makeTabView(tab, index: index)
            stackView.addArrangedSubview(tabView)
            tabButtons.append(tabView)
        }

        updateTabWidths()
    }

    private func updateTabWidths() {
        guard !tabs.isEmpty else { return }

        let edgeInsets: CGFloat = 8  // left + right padding of stackView
        let totalSpacing = CGFloat(max(0, tabs.count - 1)) * stackView.spacing
        let availableWidth = bounds.width - edgeInsets - totalSpacing
        let idealWidth = min(maxTabWidth, availableWidth / CGFloat(tabs.count))
        let tabWidth = max(minTabWidth, idealWidth)

        for constraint in tabWidthConstraints {
            constraint.constant = tabWidth
        }
    }

    override func layout() {
        super.layout()
        updateTabWidths()
    }

    private func makeTabView(_ tab: TabItem, index: Int) -> NSView {
        let container = TabButtonView(index: index, isSelected: tab.isSelected)
        container.translatesAutoresizingMaskIntoConstraints = false

        // File type icon
        let iconName = tab.isMarkdown ? "doc.richtext" : "doc.text"
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        iconView.contentTintColor = tab.isSelected ? .labelColor : .tertiaryLabelColor
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Label with fade mask
        let label = NSTextField(labelWithString: tab.title)
        label.font = NSFont.systemFont(ofSize: 12, weight: tab.isSelected ? .medium : .regular)
        label.textColor = tab.isSelected ? .labelColor : .secondaryLabelColor
        label.lineBreakMode = .byClipping
        label.translatesAutoresizingMaskIntoConstraints = false

        let labelContainer = FadingLabelView()
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        labelContainer.addSubview(label)

        let closeButton = CloseButton(index: index)
        closeButton.target = self
        closeButton.action = #selector(closeTabClicked(_:))
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        container.tabBar = self
        container.addSubview(iconView)
        container.addSubview(labelContainer)
        container.addSubview(closeButton)

        let widthConstraint = container.widthAnchor.constraint(equalToConstant: maxTabWidth)
        tabWidthConstraints.append(widthConstraint)

        NSLayoutConstraint.activate([
            widthConstraint,
            container.heightAnchor.constraint(equalToConstant: 28),

            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            labelContainer.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            labelContainer.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            labelContainer.topAnchor.constraint(equalTo: container.topAnchor),
            labelContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            label.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: labelContainer.trailingAnchor),

            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
        ])

        return container
    }

    func handleTabClick(at index: Int) {
        delegate?.tabBar(self, didSelectTabAt: index)
    }

    /// Handle a click at a point in the tab bar's own coordinate system.
    /// Used by MDViewWindow.sendEvent to bypass titlebar hitTest issues.
    func handleClickAtPoint(_ pointInSelf: NSPoint) {
        let pointInStack = stackView.convert(pointInSelf, from: self)
        for button in tabButtons {
            guard button.frame.contains(pointInStack) else { continue }
            guard let tabButton = button as? TabButtonView else { continue }
            // Check close button first
            let pointInButton = button.convert(pointInSelf, from: self)
            for subview in button.subviews {
                if subview is NSButton, subview.frame.contains(pointInButton) {
                    delegate?.tabBar(self, didCloseTabAt: tabButton.index)
                    return
                }
            }
            delegate?.tabBar(self, didSelectTabAt: tabButton.index)
            return
        }
    }

    @objc private func closeTabClicked(_ sender: CloseButton) {
        delegate?.tabBar(self, didCloseTabAt: sender.index)
    }

    override func updateLayer() {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            layer?.backgroundColor = NSColor(white: 0.15, alpha: 1.0).cgColor
        } else {
            layer?.backgroundColor = NSColor(white: 0.90, alpha: 1.0).cgColor
        }
    }
}

// MARK: - ToolbarView (outline button + search)

class ToolbarView: NSView {

    weak var tabBarDelegate: TabBarViewDelegate?
    weak var parentTabBar: TabBarView?

    private let outlineButton = NSButton()
    private let reloadButton = NSButton()
    private let pathLabel = NSTextField(labelWithString: "")
    private let searchField = NSSearchField()
    private let searchCountLabel = NSTextField(labelWithString: "")
    private let infoButton = NSButton()

    // Info data
    private var infoWords = 0
    private var infoChars = 0
    private var infoLines = 0
    private var infoEncoding = ""
    private var infoMode = ""

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

        outlineButton.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle outline")
        outlineButton.imageScaling = .scaleProportionallyDown
        outlineButton.isBordered = false
        outlineButton.bezelStyle = .accessoryBarAction
        outlineButton.target = self
        outlineButton.action = #selector(outlineButtonClicked)
        outlineButton.contentTintColor = .secondaryLabelColor
        outlineButton.toolTip = "Show outline"
        outlineButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outlineButton)

        reloadButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Reload")
        reloadButton.imageScaling = .scaleProportionallyDown
        reloadButton.isBordered = false
        reloadButton.bezelStyle = .accessoryBarAction
        reloadButton.target = self
        reloadButton.action = #selector(reloadButtonClicked)
        reloadButton.contentTintColor = .secondaryLabelColor
        reloadButton.toolTip = "Reload"
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reloadButton)

        pathLabel.font = NSFont.systemFont(ofSize: 11)
        pathLabel.textColor = .tertiaryLabelColor
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pathLabel)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        searchField.placeholderString = "Search"
        searchField.font = NSFont.systemFont(ofSize: 12)
        searchField.focusRingType = .none
        searchField.controlSize = .small
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.delegate = self
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false
        addSubview(searchField)

        searchCountLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        searchCountLabel.textColor = .tertiaryLabelColor
        searchCountLabel.alignment = .right
        searchCountLabel.translatesAutoresizingMaskIntoConstraints = false
        searchCountLabel.isHidden = true
        addSubview(searchCountLabel)

        infoButton.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "File info")
        infoButton.imageScaling = .scaleProportionallyDown
        infoButton.isBordered = false
        infoButton.contentTintColor = .secondaryLabelColor
        infoButton.target = self
        infoButton.action = #selector(showInfoPopover(_:))
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoButton)

        NSLayoutConstraint.activate([
            outlineButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            outlineButton.topAnchor.constraint(equalTo: topAnchor),
            outlineButton.bottomAnchor.constraint(equalTo: separator.topAnchor),
            outlineButton.widthAnchor.constraint(equalToConstant: 38),

            reloadButton.leadingAnchor.constraint(equalTo: outlineButton.trailingAnchor, constant: -4),
            reloadButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            reloadButton.widthAnchor.constraint(equalToConstant: 26),
            reloadButton.heightAnchor.constraint(equalToConstant: 26),

            pathLabel.leadingAnchor.constraint(equalTo: reloadButton.trailingAnchor, constant: 4),
            pathLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            pathLabel.trailingAnchor.constraint(lessThanOrEqualTo: searchField.leadingAnchor, constant: -10),

            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),

            searchField.trailingAnchor.constraint(equalTo: infoButton.leadingAnchor, constant: -6),
            searchField.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchField.widthAnchor.constraint(equalToConstant: 160),

            searchCountLabel.trailingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: -20),
            searchCountLabel.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),

            infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            infoButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 18),
            infoButton.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    @objc private func outlineButtonClicked() {
        guard let tabBar = parentTabBar else { return }
        tabBarDelegate?.tabBarDidToggleOutline(tabBar)
    }

    @objc private func reloadButtonClicked() {
        guard let tabBar = parentTabBar else { return }
        tabBarDelegate?.tabBarDidReload(tabBar)
    }

    func updateFilePath(_ path: String?) {
        pathLabel.stringValue = path ?? ""
    }

    func updateFileInfo(words: Int, characters: Int, lines: Int, encoding: String, mode: String) {
        infoWords = words
        infoChars = characters
        infoLines = lines
        infoEncoding = encoding
        infoMode = mode
    }

    @objc private func showInfoPopover(_ sender: NSButton) {
        let popover = NSPopover()
        popover.behavior = .transient

        let vc = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))

        let text = """
        \(infoMode)
        \(infoLines) lines  ·  \(infoWords) words  ·  \(infoChars) chars
        Encoding: \(infoEncoding)
        """

        let label = NSTextField(wrappingLabelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])

        vc.view = view
        popover.contentViewController = vc
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func focusSearchField() {
        window?.makeFirstResponder(searchField)
    }

    func updateSearchCount(current: Int, total: Int) {
        if total > 0 {
            searchCountLabel.stringValue = "\(current)/\(total)"
            searchCountLabel.isHidden = false
        } else if !searchField.stringValue.isEmpty {
            searchCountLabel.stringValue = "0/0"
            searchCountLabel.isHidden = false
        } else {
            searchCountLabel.isHidden = true
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

extension ToolbarView: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSSearchField, let tabBar = parentTabBar else { return }
        let query = field.stringValue
        if query.isEmpty {
            searchCountLabel.isHidden = true
            tabBarDelegate?.tabBarDidEndSearch(tabBar)
        } else {
            tabBarDelegate?.tabBar(tabBar, didSearch: query)
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSSearchField, let tabBar = parentTabBar else { return }
        if field.stringValue.isEmpty {
            searchCountLabel.isHidden = true
            tabBarDelegate?.tabBarDidEndSearch(tabBar)
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            guard let tabBar = parentTabBar else { return false }
            tabBarDelegate?.tabBarDidSearchNext(tabBar)
            return true
        }
        return false
    }
}

// MARK: - TabButtonView

private class TabButtonView: NSView {
    let index: Int
    let isSelected: Bool
    weak var tabBar: TabBarView?

    override var mouseDownCanMoveWindow: Bool { false }

    init(index: Int, isSelected: Bool) {
        self.index = index
        self.isSelected = isSelected
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]  // top corners only (flipped coords)
        layer?.masksToBounds = true
        updateBackground()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        // Check if click is on the close button — if so, let it handle it
        for subview in subviews where subview is CloseButton {
            if subview.frame.contains(location) {
                super.mouseDown(with: event)
                return
            }
        }
        tabBar?.handleTabClick(at: index)
    }

    private func updateBackground() {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isSelected {
            // Match toolbar color so active tab blends into toolbar
            layer?.backgroundColor = isDark
                ? NSColor(white: 0.18, alpha: 1.0).cgColor
                : NSColor(white: 0.93, alpha: 1.0).cgColor
        } else {
            layer?.backgroundColor = isDark
                ? NSColor(white: 0.15, alpha: 1.0).cgColor
                : NSColor(white: 0.90, alpha: 1.0).cgColor
        }
    }

    override func updateLayer() {
        updateBackground()
    }
}

// MARK: - FadingLabelView

private class FadingLabelView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        updateFadeMask()
    }

    private func updateFadeMask() {
        guard let label = subviews.first as? NSTextField else { return }
        let labelWidth = label.intrinsicContentSize.width
        let containerWidth = bounds.width

        if labelWidth > containerWidth && containerWidth > 0 {
            let fadeWidth: CGFloat = 20
            let mask = CAGradientLayer()
            mask.frame = bounds
            mask.colors = [
                NSColor.white.cgColor,
                NSColor.white.cgColor,
                NSColor.clear.cgColor,
            ]
            mask.startPoint = CGPoint(x: 0, y: 0.5)
            mask.endPoint = CGPoint(x: 1, y: 0.5)
            mask.locations = [
                0,
                NSNumber(value: Double(max(0, containerWidth - fadeWidth) / containerWidth)),
                1,
            ]
            layer?.mask = mask
        } else {
            layer?.mask = nil
        }
    }
}

// MARK: - CloseButton

private class CloseButton: NSButton {
    let index: Int

    override var mouseDownCanMoveWindow: Bool { false }

    init(index: Int) {
        self.index = index
        super.init(frame: .zero)
        image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close tab")
        imageScaling = .scaleProportionallyDown
        isBordered = false
        (cell as? NSButtonCell)?.imageScaling = .scaleProportionallyDown
        contentTintColor = .tertiaryLabelColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }
}
