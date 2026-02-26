import Cocoa

struct OutlineItem {
    let title: String
    let level: Int
    let lineIndex: Int
}

class OutlineView: NSView {

    var onItemSelected: ((OutlineItem) -> Void)?
    var onResize: ((CGFloat) -> Void)?

    private let scrollView = NSScrollView()
    private let stackView = NSStackView()
    private var items: [OutlineItem] = []
    private let resizeHandle = OutlineResizeHandle()

    static let minWidth: CGFloat = 140
    static let maxWidth: CGFloat = 400

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
        updateBackground()

        let header = NSTextField(labelWithString: "Outline")
        header.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        header.textColor = .secondaryLabelColor
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView = FlippedClipView()
        scrollView.contentView.drawsBackground = false
        addSubview(scrollView)

        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.edgeInsets = NSEdgeInsets(top: 4, left: 0, bottom: 8, right: 0)
        scrollView.documentView = stackView

        // Separator on the right edge
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        // Resize handle
        resizeHandle.translatesAutoresizingMaskIntoConstraints = false
        resizeHandle.onDrag = { [weak self] deltaX in
            guard let self = self else { return }
            let newWidth = (self.frame.width + deltaX)
                .clamped(to: Self.minWidth...Self.maxWidth)
            self.onResize?(newWidth)
        }
        addSubview(resizeHandle)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),

            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.widthAnchor.constraint(equalToConstant: 1),

            resizeHandle.topAnchor.constraint(equalTo: topAnchor),
            resizeHandle.bottomAnchor.constraint(equalTo: bottomAnchor),
            resizeHandle.trailingAnchor.constraint(equalTo: trailingAnchor),
            resizeHandle.widthAnchor.constraint(equalToConstant: 6),
        ])
    }

    func update(items: [OutlineItem]) {
        self.items = items

        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, item) in items.enumerated() {
            let button = OutlineItemButton(item: item, index: index)
            button.target = self
            button.action = #selector(itemClicked(_:))
            button.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(button)

            button.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            button.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }
    }

    @objc private func itemClicked(_ sender: OutlineItemButton) {
        let item = items[sender.index]
        onItemSelected?(item)
    }

    private func updateBackground() {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            layer?.backgroundColor = NSColor(white: 0.13, alpha: 1.0).cgColor
        } else {
            layer?.backgroundColor = NSColor(white: 0.95, alpha: 1.0).cgColor
        }
    }

    override func updateLayer() {
        updateBackground()
    }
}

// MARK: - OutlineItemButton

private class OutlineItemButton: NSButton {
    let index: Int
    private let itemLevel: Int
    private let itemTitle: String
    private let indent: CGFloat
    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    init(item: OutlineItem, index: Int) {
        self.index = index
        self.itemLevel = item.level
        self.itemTitle = item.title
        self.indent = CGFloat(max(0, item.level - 1)) * 16
        super.init(frame: .zero)

        isBordered = false
        // Prevent default button flash by using momentary change type
        setButtonType(.momentaryChange)
        (cell as? NSButtonCell)?.lineBreakMode = .byTruncatingTail
        (cell as? NSButtonCell)?.highlightsBy = []

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(greaterThanOrEqualToConstant: 22).isActive = true

        updateTitle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTitle() {
        let textFont = itemLevel == 1
            ? NSFont.systemFont(ofSize: 12, weight: .medium)
            : NSFont.systemFont(ofSize: 12)
        let textColor: NSColor = itemLevel == 1 ? .labelColor : .secondaryLabelColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 12 + indent
        paragraphStyle.headIndent = 12 + indent
        paragraphStyle.lineBreakMode = .byTruncatingTail

        var attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        if isHovered {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        self.attributedTitle = NSAttributedString(string: itemTitle, attributes: attributes)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        updateTitle()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        updateTitle()
    }

    override func mouseDown(with event: NSEvent) {
        // Send action directly without default NSButton highlight flash
        sendAction(action, to: target)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}

// MARK: - OutlineResizeHandle

private class OutlineResizeHandle: NSView {
    var onDrag: ((CGFloat) -> Void)?
    private var initialX: CGFloat = 0

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        updateBackground()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        updateBackground()
    }

    private func updateBackground() {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor(white: 0.18, alpha: 1.0).cgColor
            : NSColor(white: 0.93, alpha: 1.0).cgColor
    }

    override func updateLayer() {
        updateBackground()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        initialX = event.locationInWindow.x
    }

    override func mouseDragged(with event: NSEvent) {
        let delta = event.locationInWindow.x - initialX
        initialX = event.locationInWindow.x
        onDrag?(delta)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw grip dots in the center
        let dotColor: NSColor = .tertiaryLabelColor
        dotColor.setFill()

        let dotSize: CGFloat = 2
        let dotSpacing: CGFloat = 4
        let dotCount = 3
        let totalHeight = CGFloat(dotCount) * dotSize + CGFloat(dotCount - 1) * dotSpacing
        let startY = (bounds.height - totalHeight) / 2
        let x = (bounds.width - dotSize) / 2

        for i in 0..<dotCount {
            let y = startY + CGFloat(i) * (dotSize + dotSpacing)
            let dot = NSRect(x: x, y: y, width: dotSize, height: dotSize)
            NSBezierPath(ovalIn: dot).fill()
        }
    }
}

// MARK: - Comparable Clamped

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Flipped Clip View (top-aligned content)

private class FlippedClipView: NSClipView {
    override var isFlipped: Bool { true }
}
