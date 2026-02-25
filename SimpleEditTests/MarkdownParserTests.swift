import XCTest
@testable import SimpleEdit

final class MarkdownParserTests: XCTestCase {

    let parser = MarkdownParser()

    func testHeadings() {
        let text = "# Heading 1\n## Heading 2\n### Heading 3"
        let nodes = parser.parse(text)
        let headings = nodes.filter {
            if case .heading = $0.type { return true }
            return false
        }
        XCTAssertEqual(headings.count, 3)

        if case .heading(let level) = headings[0].type {
            XCTAssertEqual(level, 1)
        }
        if case .heading(let level) = headings[1].type {
            XCTAssertEqual(level, 2)
        }
        if case .heading(let level) = headings[2].type {
            XCTAssertEqual(level, 3)
        }
    }

    func testBold() {
        let text = "This is **bold** text"
        let nodes = parser.parse(text)
        let bold = nodes.filter {
            if case .bold = $0.type { return true }
            return false
        }
        XCTAssertEqual(bold.count, 1)
    }

    func testItalic() {
        let text = "This is *italic* text"
        let nodes = parser.parse(text)
        let italic = nodes.filter {
            if case .italic = $0.type { return true }
            return false
        }
        XCTAssertEqual(italic.count, 1)
    }

    func testInlineCode() {
        let text = "Use `print()` to debug"
        let nodes = parser.parse(text)
        let code = nodes.filter {
            if case .code = $0.type { return true }
            return false
        }
        XCTAssertEqual(code.count, 1)
    }

    func testCodeBlock() {
        let text = "```swift\nlet x = 1\n```"
        let nodes = parser.parse(text)
        let blocks = nodes.filter {
            if case .codeBlock = $0.type { return true }
            return false
        }
        XCTAssertEqual(blocks.count, 1)
        if case .codeBlock(let lang) = blocks[0].type {
            XCTAssertEqual(lang, "swift")
        }
    }

    func testLinks() {
        let text = "Visit [Google](https://google.com) today"
        let nodes = parser.parse(text)
        let links = nodes.filter {
            if case .link = $0.type { return true }
            return false
        }
        XCTAssertEqual(links.count, 1)
    }

    func testBlockquote() {
        let text = "> This is a quote"
        let nodes = parser.parse(text)
        let quotes = nodes.filter {
            if case .blockquote = $0.type { return true }
            return false
        }
        XCTAssertEqual(quotes.count, 1)
    }

    func testHorizontalRule() {
        let text = "---"
        let nodes = parser.parse(text)
        let rules = nodes.filter {
            if case .horizontalRule = $0.type { return true }
            return false
        }
        XCTAssertEqual(rules.count, 1)
    }

    func testStrikethrough() {
        let text = "This is ~~deleted~~ text"
        let nodes = parser.parse(text)
        let strikes = nodes.filter {
            if case .strikethrough = $0.type { return true }
            return false
        }
        XCTAssertEqual(strikes.count, 1)
    }

    func testUnorderedList() {
        let text = "- item 1\n- item 2"
        let nodes = parser.parse(text)
        let lists = nodes.filter {
            if case .unorderedList = $0.type { return true }
            return false
        }
        XCTAssertEqual(lists.count, 2)
    }

    func testCheckbox() {
        let text = "- [ ] unchecked\n- [x] checked"
        let nodes = parser.parse(text)
        let checkboxes = nodes.filter {
            if case .checkbox = $0.type { return true }
            return false
        }
        XCTAssertEqual(checkboxes.count, 2)
    }

    func testHTMLGeneration() {
        let text = "# Hello\n\nThis is **bold**."
        let html = parser.toHTML(text)
        XCTAssertTrue(html.contains("<h1>"))
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
    }
}
