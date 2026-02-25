import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    // Register custom document controller before NSApp initializes the default one
    private let documentController = SimpleEditDocumentController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Activate app and bring to front (needed when running as raw binary, not .app bundle)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Set Dock icon
        NSApp.applicationIconImage = makeAppIcon(size: 512)

        setupMainMenu()

        // Ensure main window is ready
        MainWindowController.shared.showWindow()

        // Open files passed as command-line arguments
        let args = ProcessInfo.processInfo.arguments.dropFirst()
        var openedFile = false
        for arg in args {
            let url = URL(fileURLWithPath: arg)
            if FileManager.default.fileExists(atPath: url.path) {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
                openedFile = true
            }
        }

        if !openedFile {
            _ = try? NSDocumentController.shared.openUntitledDocumentAndDisplay(true)
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About SimpleEdit", action: #selector(showAbout(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Preferences…", action: #selector(showPreferences(_:)), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide SimpleEdit", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthersItem = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit SimpleEdit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open…", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Print…", action: #selector(NSDocument.printDocument(_:)), keyEquivalent: "p")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu (copy, select all, find)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Find…", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "f")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Toggle Word Wrap", action: #selector(EditorViewController.toggleWordWrap(_:)), keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        // Help menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "SimpleEdit Help", action: #selector(NSApplication.showHelp(_:)), keyEquivalent: "?")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        NSApp.helpMenu = helpMenu

        NSApp.mainMenu = mainMenu
    }

    @objc private func showPreferences(_ sender: Any?) {
        PreferencesWindowController.shared.showWindow(sender)
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "SimpleEdit",
            .applicationVersion: "1.0.0",
            .version: "1",
            .credits: NSAttributedString(
                string: "A lightweight native macOS viewer for plain text and Markdown files.",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            ),
            .applicationIcon: NSApp.applicationIconImage as Any
        ])
    }

    // MARK: - App Icon

    private func makeAppIcon(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let padding = size * 0.08
        let pageRect = NSRect(x: padding, y: padding,
                              width: size - padding * 2, height: size - padding * 2)
        let cornerRadius = size * 0.08

        // Shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -size * 0.02)
        shadow.shadowBlurRadius = size * 0.04
        shadow.set()

        // Page background
        let page = NSBezierPath(roundedRect: pageRect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.white.setFill()
        page.fill()

        // Remove shadow for subsequent drawing
        NSShadow().set()

        // Page border
        NSColor(white: 0.82, alpha: 1).setStroke()
        page.lineWidth = size * 0.005
        page.stroke()

        // Dog-ear fold (top-right corner)
        let foldSize = size * 0.12
        let foldX = pageRect.maxX - foldSize
        let foldY = pageRect.maxY - foldSize
        let fold = NSBezierPath()
        fold.move(to: NSPoint(x: foldX, y: pageRect.maxY))
        fold.line(to: NSPoint(x: pageRect.maxX, y: foldY))
        fold.line(to: NSPoint(x: foldX, y: foldY))
        fold.close()
        NSColor(white: 0.92, alpha: 1).setFill()
        fold.fill()
        NSColor(white: 0.78, alpha: 1).setStroke()
        fold.lineWidth = size * 0.004
        fold.stroke()

        // Text lines
        let lineInset = size * 0.18
        let lineHeight = size * 0.028
        let lineSpacing = size * 0.06
        let startY = pageRect.maxY - size * 0.28

        // Title line (thicker, like a heading)
        let titleRect = NSRect(x: lineInset, y: startY,
                               width: size * 0.40, height: lineHeight * 1.6)
        NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.25, alpha: 1).setFill()
        NSBezierPath(roundedRect: titleRect, xRadius: lineHeight * 0.4, yRadius: lineHeight * 0.4).fill()

        // Body lines
        let bodyColor = NSColor(white: 0.62, alpha: 1)
        let lineWidths: [CGFloat] = [0.58, 0.52, 0.62, 0.45, 0.55, 0.38]
        for (i, widthFraction) in lineWidths.enumerated() {
            let y = startY - lineSpacing * CGFloat(i + 1) - lineHeight
            let rect = NSRect(x: lineInset, y: y,
                              width: size * widthFraction, height: lineHeight)
            bodyColor.setFill()
            NSBezierPath(roundedRect: rect, xRadius: lineHeight * 0.4, yRadius: lineHeight * 0.4).fill()
        }

        // Markdown "#" accent in top-left area
        let hashStr = "#" as NSString
        let hashFont = NSFont.systemFont(ofSize: size * 0.13, weight: .bold)
        let hashAttrs: [NSAttributedString.Key: Any] = [
            .font: hashFont,
            .foregroundColor: NSColor(calibratedRed: 0.30, green: 0.55, blue: 0.95, alpha: 0.85)
        ]
        let hashSize = hashStr.size(withAttributes: hashAttrs)
        hashStr.draw(at: NSPoint(x: lineInset - hashSize.width - size * 0.02,
                                  y: startY - hashSize.height * 0.15),
                     withAttributes: hashAttrs)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
