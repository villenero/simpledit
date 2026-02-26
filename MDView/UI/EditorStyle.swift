import Cocoa

struct EditorStyle {
    let name: String
    let font: NSFont
    let textColor: NSColor
    let backgroundColor: NSColor
    let css: CSSTokens

    struct CSSTokens {
        let fontFamily: String
        let fontSize: String
        let bodyColor: String
        let bodyBg: String
        let linkColor: String
        let codeBg: String
        let codeFontFamily: String
        let blockquoteBorderColor: String
        let blockquoteTextColor: String
        let hrColor: String
        let tableBorderColor: String
        let thBg: String
        let trEvenBg: String
        let mermaidTheme: String
    }

    var markdownCSS: String {
        let t = css
        return """
        body {
            font-family: \(t.fontFamily);
            font-size: \(t.fontSize);
            line-height: 1.6;
            max-width: 720px;
            margin: 0 auto;
            padding: 20px 24px;
            color: \(t.bodyColor);
            background: \(t.bodyBg);
        }

        h1 { font-size: 28px; font-weight: 700; margin: 24px 0 12px; }
        h2 { font-size: 22px; font-weight: 700; margin: 20px 0 10px; }
        h3 { font-size: 18px; font-weight: 600; margin: 18px 0 8px; }
        h4 { font-size: 16px; font-weight: 600; margin: 16px 0 6px; }
        h5 { font-size: 14px; font-weight: 600; margin: 14px 0 4px; }
        h6 { font-size: 12px; font-weight: 600; margin: 12px 0 4px; }

        p { margin: 0 0 12px; }

        a { color: \(t.linkColor); text-decoration: none; }
        a:hover { text-decoration: underline; }

        code {
            font-family: \(t.codeFontFamily);
            font-size: 12px;
            background: \(t.codeBg);
            padding: 2px 6px;
            border-radius: 4px;
        }

        pre {
            background: \(t.codeBg);
            padding: 12px 16px;
            border-radius: 8px;
            overflow-x: auto;
            line-height: 1.15;
        }
        pre code { background: none; padding: 0; }

        blockquote {
            margin: 0 0 12px;
            padding: 4px 16px;
            border-left: 3px solid \(t.blockquoteBorderColor);
            color: \(t.blockquoteTextColor);
        }

        img { max-width: 100%; height: auto; border-radius: 8px; }

        hr { border: none; border-top: 1px solid \(t.hrColor); margin: 20px 0; }

        ul, ol { padding-left: 24px; margin: 0 0 12px; }
        li { margin: 4px 0; }
        li input[type="checkbox"] { margin-right: 6px; }

        del { color: \(t.blockquoteTextColor); }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 12px 0;
            font-size: 13px;
        }
        th, td {
            border: 1px solid \(t.tableBorderColor);
            padding: 8px 12px;
            text-align: left;
        }
        th { font-weight: 600; background-color: \(t.thBg); }
        tr:nth-child(even) td { background-color: \(t.trEvenBg); }

        .mermaid { text-align: center; margin: 16px 0; overflow-x: auto; }
        .mermaid svg { max-width: 100%; }
        """
    }
}

// MARK: - Registry

extension EditorStyle {

    static let all: [EditorStyle] = [light, dark, vintageTerminal, elegant, nord, solarized]

    static let light = EditorStyle(
        name: "Light",
        font: .monospacedSystemFont(ofSize: 13, weight: .regular),
        textColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1),
        backgroundColor: .white,
        css: CSSTokens(
            fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif",
            fontSize: "14px",
            bodyColor: "#1d1d1f",
            bodyBg: "#ffffff",
            linkColor: "#0071e3",
            codeBg: "rgba(0,0,0,0.04)",
            codeFontFamily: "'SF Mono', Menlo, monospace",
            blockquoteBorderColor: "#0071e3",
            blockquoteTextColor: "#6e6e73",
            hrColor: "#d2d2d7",
            tableBorderColor: "#d2d2d7",
            thBg: "rgba(0,0,0,0.04)",
            trEvenBg: "rgba(0,0,0,0.02)",
            mermaidTheme: "default"
        )
    )

    static let dark = EditorStyle(
        name: "Dark",
        font: .monospacedSystemFont(ofSize: 13, weight: .regular),
        textColor: NSColor(red: 0xd4/255.0, green: 0xd4/255.0, blue: 0xd4/255.0, alpha: 1),
        backgroundColor: NSColor(red: 0x1e/255.0, green: 0x1e/255.0, blue: 0x1e/255.0, alpha: 1),
        css: CSSTokens(
            fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif",
            fontSize: "14px",
            bodyColor: "#d4d4d4",
            bodyBg: "#1e1e1e",
            linkColor: "#64d2ff",
            codeBg: "rgba(255,255,255,0.06)",
            codeFontFamily: "'SF Mono', Menlo, monospace",
            blockquoteBorderColor: "#64d2ff",
            blockquoteTextColor: "#a1a1a6",
            hrColor: "#38383a",
            tableBorderColor: "#38383a",
            thBg: "rgba(255,255,255,0.08)",
            trEvenBg: "rgba(255,255,255,0.04)",
            mermaidTheme: "dark"
        )
    )

    static let vintageTerminal = EditorStyle(
        name: "Vintage Terminal",
        font: NSFont(name: "Courier", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular),
        textColor: NSColor(red: 0x33/255.0, green: 0xff/255.0, blue: 0x00/255.0, alpha: 1),
        backgroundColor: NSColor(red: 0x2b/255.0, green: 0x1d/255.0, blue: 0x0e/255.0, alpha: 1),
        css: CSSTokens(
            fontFamily: "Courier, 'Courier New', monospace",
            fontSize: "14px",
            bodyColor: "#33ff00",
            bodyBg: "#2b1d0e",
            linkColor: "#ffcc00",
            codeBg: "rgba(51,255,0,0.08)",
            codeFontFamily: "Courier, 'Courier New', monospace",
            blockquoteBorderColor: "#33ff00",
            blockquoteTextColor: "#77cc44",
            hrColor: "#33ff00",
            tableBorderColor: "rgba(51,255,0,0.25)",
            thBg: "rgba(51,255,0,0.08)",
            trEvenBg: "rgba(51,255,0,0.04)",
            mermaidTheme: "dark"
        )
    )

    static let nord = EditorStyle(
        name: "Nord",
        font: .monospacedSystemFont(ofSize: 13, weight: .regular),
        textColor: NSColor(red: 0xd8/255.0, green: 0xde/255.0, blue: 0xe9/255.0, alpha: 1),
        backgroundColor: NSColor(red: 0x2e/255.0, green: 0x34/255.0, blue: 0x40/255.0, alpha: 1),
        css: CSSTokens(
            fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif",
            fontSize: "14px",
            bodyColor: "#d8dee9",
            bodyBg: "#2e3440",
            linkColor: "#88c0d0",
            codeBg: "rgba(136,192,208,0.08)",
            codeFontFamily: "'SF Mono', Menlo, monospace",
            blockquoteBorderColor: "#88c0d0",
            blockquoteTextColor: "#81a1c1",
            hrColor: "#4c566a",
            tableBorderColor: "#4c566a",
            thBg: "rgba(136,192,208,0.08)",
            trEvenBg: "rgba(136,192,208,0.04)",
            mermaidTheme: "dark"
        )
    )

    static let solarized = EditorStyle(
        name: "Solarized",
        font: NSFont(name: "Menlo", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular),
        textColor: NSColor(red: 0x65/255.0, green: 0x7b/255.0, blue: 0x83/255.0, alpha: 1),
        backgroundColor: NSColor(red: 0xfd/255.0, green: 0xf6/255.0, blue: 0xe3/255.0, alpha: 1),
        css: CSSTokens(
            fontFamily: "Menlo, 'SF Mono', monospace",
            fontSize: "13px",
            bodyColor: "#657b83",
            bodyBg: "#fdf6e3",
            linkColor: "#268bd2",
            codeBg: "rgba(38,139,210,0.06)",
            codeFontFamily: "Menlo, 'SF Mono', monospace",
            blockquoteBorderColor: "#268bd2",
            blockquoteTextColor: "#93a1a1",
            hrColor: "#eee8d5",
            tableBorderColor: "#eee8d5",
            thBg: "rgba(38,139,210,0.06)",
            trEvenBg: "rgba(38,139,210,0.03)",
            mermaidTheme: "default"
        )
    )

    static let elegant = EditorStyle(
        name: "Elegant",
        font: NSFont(name: "Georgia", size: 15) ?? .systemFont(ofSize: 15),
        textColor: NSColor(red: 0x3b/255.0, green: 0x2f/255.0, blue: 0x24/255.0, alpha: 1),
        backgroundColor: NSColor(red: 0xf5/255.0, green: 0xf0/255.0, blue: 0xe8/255.0, alpha: 1),
        css: CSSTokens(
            fontFamily: "Georgia, 'Times New Roman', serif",
            fontSize: "15px",
            bodyColor: "#3b2f24",
            bodyBg: "#f5f0e8",
            linkColor: "#8b4513",
            codeBg: "rgba(139,69,19,0.06)",
            codeFontFamily: "'SF Mono', Menlo, monospace",
            blockquoteBorderColor: "#8b4513",
            blockquoteTextColor: "#7a6a5a",
            hrColor: "#c4b5a0",
            tableBorderColor: "#c4b5a0",
            thBg: "rgba(139,69,19,0.06)",
            trEvenBg: "rgba(139,69,19,0.03)",
            mermaidTheme: "default"
        )
    )
}
