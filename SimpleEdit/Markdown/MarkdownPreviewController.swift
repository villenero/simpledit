import Cocoa
import WebKit

class MarkdownPreviewController: NSViewController {

    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 400, height: 600), configuration: config)
        webView.allowsMagnification = true
        self.view = webView
    }

    func loadHTML(_ bodyHTML: String) {
        let fullHTML = wrapInTemplate(bodyHTML)
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }

    private func wrapInTemplate(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        \(Self.previewCSS)
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    static let previewCSS: String = """
    :root {
        color-scheme: light dark;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
        font-size: 14px;
        line-height: 1.6;
        max-width: 720px;
        margin: 0 auto;
        padding: 20px 24px;
        color: #1d1d1f;
        background: #ffffff;
    }

    @media (prefers-color-scheme: dark) {
        body {
            color: #f5f5f7;
            background: #1d1d1f;
        }
        a { color: #64d2ff; }
        code, pre {
            background: rgba(255,255,255,0.06);
        }
        blockquote {
            border-color: #64d2ff;
            color: #a1a1a6;
        }
        hr {
            border-color: #38383a;
        }
    }

    h1 { font-size: 28px; font-weight: 700; margin: 24px 0 12px; }
    h2 { font-size: 22px; font-weight: 700; margin: 20px 0 10px; }
    h3 { font-size: 18px; font-weight: 600; margin: 18px 0 8px; }
    h4 { font-size: 16px; font-weight: 600; margin: 16px 0 6px; }
    h5 { font-size: 14px; font-weight: 600; margin: 14px 0 4px; }
    h6 { font-size: 12px; font-weight: 600; margin: 12px 0 4px; }

    p { margin: 0 0 12px; }

    a {
        color: #0071e3;
        text-decoration: none;
    }
    a:hover { text-decoration: underline; }

    code {
        font-family: "SF Mono", Menlo, monospace;
        font-size: 12px;
        background: rgba(0,0,0,0.04);
        padding: 2px 6px;
        border-radius: 4px;
    }

    pre {
        background: rgba(0,0,0,0.04);
        padding: 12px 16px;
        border-radius: 8px;
        overflow-x: auto;
    }
    pre code {
        background: none;
        padding: 0;
    }

    blockquote {
        margin: 0 0 12px;
        padding: 4px 16px;
        border-left: 3px solid #0071e3;
        color: #6e6e73;
    }

    img {
        max-width: 100%;
        height: auto;
        border-radius: 8px;
    }

    hr {
        border: none;
        border-top: 1px solid #d2d2d7;
        margin: 20px 0;
    }

    ul, ol {
        padding-left: 24px;
        margin: 0 0 12px;
    }

    li { margin: 4px 0; }

    li input[type="checkbox"] {
        margin-right: 6px;
    }

    del {
        color: #86868b;
    }

    table {
        border-collapse: collapse;
        width: 100%;
        margin: 12px 0;
    }
    th, td {
        border: 1px solid #d2d2d7;
        padding: 8px 12px;
        text-align: left;
    }
    th { font-weight: 600; }
    """
}
