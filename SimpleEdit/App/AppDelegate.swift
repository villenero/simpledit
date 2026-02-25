import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Activate app and bring to front (needed when running as raw binary, not .app bundle)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Set Dock icon
        if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png") {
            NSApp.applicationIconImage = NSImage(contentsOfFile: iconPath)
        } else if let iconPath = Bundle.main.executableURL?
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/icon.png").path,
            FileManager.default.fileExists(atPath: iconPath) {
            NSApp.applicationIconImage = NSImage(contentsOfFile: iconPath)
        }

        setupMainMenu()

        // Open files passed as command-line arguments
        let args = ProcessInfo.processInfo.arguments.dropFirst()
        var openedFile = false
        for arg in args {
            let url = URL(fileURLWithPath: arg)
            if FileManager.default.fileExists(atPath: url.path) {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { doc, _, _ in
                    // Bring window to front
                    doc?.windowControllers.first?.window?.makeKeyAndOrderFront(nil)
                }
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
        appMenu.addItem(withTitle: "About SimpleEdit", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
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
        fileMenu.addItem(withTitle: "New", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open…", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
        let saveAsItem = fileMenu.addItem(withTitle: "Save As…", action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S")
        saveAsItem.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Revert to Saved", action: #selector(NSDocument.revertToSaved(_:)), keyEquivalent: "")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Print…", action: #selector(NSDocument.printDocument(_:)), keyEquivalent: "p")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Find…", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "f")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Format menu
        let formatMenuItem = NSMenuItem()
        let formatMenu = NSMenu(title: "Format")
        formatMenu.addItem(withTitle: "Show Fonts", action: #selector(NSFontManager.orderFrontFontPanel(_:)), keyEquivalent: "t")
        formatMenu.addItem(.separator())
        formatMenu.addItem(withTitle: "Toggle Word Wrap", action: #selector(EditorViewController.toggleWordWrap(_:)), keyEquivalent: "")
        formatMenuItem.submenu = formatMenu
        mainMenu.addItem(formatMenuItem)

        // Markdown menu
        let mdMenuItem = NSMenuItem()
        let mdMenu = NSMenu(title: "Markdown")
        mdMenu.addItem(withTitle: "Source Mode", action: #selector(EditorViewController.setSourceMode(_:)), keyEquivalent: "1")
        mdMenu.addItem(withTitle: "Styled Source Mode", action: #selector(EditorViewController.setStyledMode(_:)), keyEquivalent: "2")
        let previewItem = mdMenu.addItem(withTitle: "Toggle Preview", action: #selector(EditorViewController.togglePreview(_:)), keyEquivalent: "p")
        previewItem.keyEquivalentModifierMask = [.command, .shift]
        mdMenu.addItem(.separator())
        mdMenu.addItem(withTitle: "Bold", action: #selector(MarkdownToolbar.boldAction(_:)), keyEquivalent: "b")
        mdMenu.addItem(withTitle: "Italic", action: #selector(MarkdownToolbar.italicAction(_:)), keyEquivalent: "i")
        mdMenu.addItem(withTitle: "Code", action: #selector(MarkdownToolbar.codeAction(_:)), keyEquivalent: "e")
        mdMenu.addItem(withTitle: "Link", action: #selector(MarkdownToolbar.linkAction(_:)), keyEquivalent: "k")
        let toolbarToggle = mdMenu.addItem(withTitle: "Toggle Format Toolbar", action: #selector(EditorViewController.toggleMarkdownToolbar(_:)), keyEquivalent: "t")
        toolbarToggle.keyEquivalentModifierMask = [.command, .shift]
        mdMenuItem.submenu = mdMenu
        mainMenu.addItem(mdMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let tabSizeItem = NSMenuItem(title: "Tab Size", action: nil, keyEquivalent: "")
        let tabSubMenu = NSMenu()
        for size in [2, 4, 8] {
            let item = NSMenuItem(title: "\(size) Spaces", action: #selector(EditorViewController.setTabSize(_:)), keyEquivalent: "")
            item.tag = size
            tabSubMenu.addItem(item)
        }
        tabSizeItem.submenu = tabSubMenu
        viewMenu.addItem(tabSizeItem)
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
}
