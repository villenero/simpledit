import Cocoa
import UniformTypeIdentifiers

class Document: NSDocument {

    var text: String = ""
    var encoding: String.Encoding = .utf8
    var isMarkdown: Bool = false

    override class var autosavesInPlace: Bool { true }
    override class var autosavesDrafts: Bool { true }

    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool { true }

    override var autosavingFileType: String? {
        isMarkdown ? "net.daringfireball.markdown" : "public.plain-text"
    }

    // MARK: - Read

    override func read(from data: Data, ofType typeName: String) throws {
        let detectedEncoding = detectEncoding(data)
        guard let content = String(data: data, encoding: detectedEncoding) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to read file with detected encoding."
            ])
        }
        self.text = content
        self.encoding = detectedEncoding
        self.isMarkdown = typeName == "net.daringfireball.markdown"
            || fileURL?.pathExtension == "md"
            || fileURL?.pathExtension == "markdown"
    }

    // MARK: - Write

    override func data(ofType typeName: String) throws -> Data {
        guard let data = text.data(using: encoding) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to encode text for saving."
            ])
        }
        return data
    }

    // MARK: - Window Controller

    override func makeWindowControllers() {
        let mainWC = MainWindowController.shared
        addWindowController(mainWC)
        mainWC.openDocument(self)
    }

    // MARK: - Document Types

    override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
        ["public.plain-text", "net.daringfireball.markdown"]
    }

    override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        switch typeName {
        case "net.daringfireball.markdown": return "md"
        default: return "txt"
        }
    }

    // MARK: - Encoding Detection

    private func detectEncoding(_ data: Data) -> String.Encoding {
        // Check BOM
        if data.count >= 3, data[0] == 0xEF, data[1] == 0xBB, data[2] == 0xBF {
            return .utf8
        }
        if data.count >= 2, data[0] == 0xFF, data[1] == 0xFE {
            return .utf16LittleEndian
        }
        if data.count >= 2, data[0] == 0xFE, data[1] == 0xFF {
            return .utf16BigEndian
        }

        // Try UTF-8 first
        if String(data: data, encoding: .utf8) != nil {
            return .utf8
        }

        // Fallback to Latin-1 (always succeeds)
        return .isoLatin1
    }
}
