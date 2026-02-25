import Cocoa

class SimpleTextView: NSTextView {

    var tabSize: Int = 4

    override func insertTab(_ sender: Any?) {
        let spaces = String(repeating: " ", count: tabSize)
        insertText(spaces, replacementRange: selectedRange())
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Cmd+click to open links in markdown
        if event.modifierFlags.contains(.command), event.type == .keyDown {
            // Let the responder chain handle it
        }
        return super.performKeyEquivalent(with: event)
    }
}
