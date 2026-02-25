import Cocoa
import UniformTypeIdentifiers

class SimpleEditDocumentController: NSDocumentController {

    override var defaultType: String? {
        "public.plain-text"
    }

    override func documentClass(forType typeName: String) -> AnyClass? {
        Document.self
    }

    override func typeForContents(of url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown", "mdown", "mkd":
            return "net.daringfireball.markdown"
        default:
            return "public.plain-text"
        }
    }
}
