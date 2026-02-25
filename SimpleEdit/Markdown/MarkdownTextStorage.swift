import Cocoa

class MarkdownTextStorage: NSTextStorage {

    private let backingStore = NSMutableAttributedString()
    private let parser: MarkdownParser
    private let styler: MarkdownStyler
    private var stylingWorkItem: DispatchWorkItem?
    private var isStyling = false

    init(parser: MarkdownParser, styler: MarkdownStyler) {
        self.parser = parser
        self.styler = styler
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) not supported")
    }

    // MARK: - NSTextStorage Primitives

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // MARK: - Process Editing

    override func processEditing() {
        if !isStyling && editedMask.contains(.editedCharacters) {
            // Apply default font to edited paragraph
            let paragraphRange = (string as NSString).paragraphRange(for: editedRange)
            isStyling = true
            backingStore.setAttributes([
                .font: ThemeManager.Fonts.body(),
                .foregroundColor: ThemeManager.Colors.editorText
            ], range: paragraphRange)
            isStyling = false
        }

        super.processEditing()

        // Schedule markdown styling only for character edits, not attribute-only changes
        if !isStyling && editedMask.contains(.editedCharacters) {
            scheduleStyling()
        }
    }

    private func scheduleStyling() {
        stylingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.applyStyling()
        }
        stylingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    func applyStyling() {
        guard !isStyling else { return }
        isStyling = true
        let nodes = parser.parse(string)
        styler.apply(nodes: nodes, to: self)
        isStyling = false
    }
}
