import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    // Register custom document controller before NSApp initializes the default one
    private let documentController = SimpleEditDocumentController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Activate app and bring to front (needed when running as raw binary, not .app bundle)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Set Dock icon
        if let iconURL = Bundle.module.url(forResource: "icon", withExtension: "png"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }

        setupMainMenu()

        // Ensure main window is ready
        MainWindowController.shared.showWindow()

        // Open files passed as command-line arguments
        let args = ProcessInfo.processInfo.arguments.dropFirst()
        for arg in args {
            let url = URL(fileURLWithPath: arg)
            if FileManager.default.fileExists(atPath: url.path) {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
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
        viewMenu.addItem(.separator())

        // Theme submenu
        let themeMenuItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu(title: "Theme")
        for (i, style) in EditorStyle.all.enumerated() {
            let item = NSMenuItem(
                title: style.name,
                action: #selector(selectTheme(_:)),
                keyEquivalent: "\(i + 1)"
            )
            item.tag = i
            themeMenu.addItem(item)
        }
        themeMenuItem.submenu = themeMenu
        viewMenu.addItem(themeMenuItem)

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

    @objc private func selectTheme(_ sender: NSMenuItem) {
        let styles = EditorStyle.all
        guard sender.tag >= 0, sender.tag < styles.count else { return }
        MainWindowController.shared.editorViewController.applyStyle(styles[sender.tag])
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

}
