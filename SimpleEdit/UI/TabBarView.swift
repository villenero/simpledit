import Cocoa

protocol TabBarViewDelegate: AnyObject {
    func tabBar(_ tabBar: TabBarView, didSelectTabAt index: Int)
    func tabBar(_ tabBar: TabBarView, didCloseTabAt index: Int)
}

struct TabItem {
    let title: String
    let isSelected: Bool
}

class TabBarView: NSView {

    weak var delegate: TabBarViewDelegate?

    private var tabs: [TabItem] = []
    private var tabButtons: [NSView] = []
    private let stackView = NSStackView()
    private let scrollView = NSScrollView()

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
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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

    private func rebuildTabs() {
        for view in tabButtons {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        tabButtons.removeAll()

        for (index, tab) in tabs.enumerated() {
            let tabView = makeTabView(tab, index: index)
            stackView.addArrangedSubview(tabView)
            tabButtons.append(tabView)
        }
    }

    private func makeTabView(_ tab: TabItem, index: Int) -> NSView {
        let container = TabButtonView(index: index, isSelected: tab.isSelected)
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: tab.title)
        label.font = NSFont.systemFont(ofSize: 12.5, weight: tab.isSelected ? .medium : .regular)
        label.textColor = tab.isSelected ? .labelColor : .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = CloseButton(index: index)
        closeButton.target = self
        closeButton.action = #selector(closeTabClicked(_:))
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        container.tabBar = self
        container.addSubview(label)
        container.addSubview(closeButton)

        // Vertical separator on the right
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sep)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: 200),

            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -6),

            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),

            sep.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sep.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            sep.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            sep.widthAnchor.constraint(equalToConstant: 1),
        ])

        return container
    }

    func handleTabClick(at index: Int) {
        delegate?.tabBar(self, didSelectTabAt: index)
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

// MARK: - TabButtonView

private class TabButtonView: NSView {
    let index: Int
    let isSelected: Bool
    weak var tabBar: TabBarView?

    init(index: Int, isSelected: Bool) {
        self.index = index
        self.isSelected = isSelected
        super.init(frame: .zero)
        wantsLayer = true
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
        if isSelected {
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                layer?.backgroundColor = NSColor(white: 0.22, alpha: 1.0).cgColor
            } else {
                layer?.backgroundColor = NSColor(white: 0.98, alpha: 1.0).cgColor
            }
        } else {
            layer?.backgroundColor = nil
        }
    }

    override func updateLayer() {
        updateBackground()
    }
}

// MARK: - CloseButton

private class CloseButton: NSButton {
    let index: Int

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
