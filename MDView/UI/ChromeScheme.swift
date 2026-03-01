import Cocoa

struct ChromeScheme {
    let name: String
    let titleBar: NSColor
    let tabBarBackground: NSColor
    let activeTab: NSColor
    let inactiveTab: NSColor
    let activeTabText: NSColor
    let inactiveTabText: NSColor
    let toolbar: NSColor
    let toolbarText: NSColor
    let toolbarIconTint: NSColor
    let outline: NSColor
    let outlineText: NSColor
    let outlineSecondaryText: NSColor
    let outlineResizeHandle: NSColor
    let statusBar: NSColor
    let statusBarText: NSColor
    let statusBarIconTint: NSColor
    let accent: NSColor

    static let light = ChromeScheme(
        name: "Light",
        titleBar: NSColor(white: 0.90, alpha: 1.0),
        tabBarBackground: NSColor(white: 0.90, alpha: 1.0),
        activeTab: NSColor(white: 0.93, alpha: 1.0),
        inactiveTab: NSColor(white: 0.90, alpha: 1.0),
        activeTabText: NSColor(white: 0.10, alpha: 1.0),
        inactiveTabText: NSColor(white: 0.40, alpha: 1.0),
        toolbar: NSColor(white: 0.93, alpha: 1.0),
        toolbarText: NSColor(white: 0.45, alpha: 1.0),
        toolbarIconTint: NSColor(white: 0.35, alpha: 1.0),
        outline: NSColor(white: 0.95, alpha: 1.0),
        outlineText: NSColor(white: 0.10, alpha: 1.0),
        outlineSecondaryText: NSColor(white: 0.40, alpha: 1.0),
        outlineResizeHandle: NSColor(white: 0.93, alpha: 1.0),
        statusBar: NSColor(white: 0.93, alpha: 1.0),
        statusBarText: NSColor(white: 0.35, alpha: 1.0),
        statusBarIconTint: NSColor(white: 0.35, alpha: 1.0),
        accent: NSColor(red: 0.30, green: 0.55, blue: 0.95, alpha: 1.0)
    )

    static let dark = ChromeScheme(
        name: "Dark",
        titleBar: NSColor(white: 0.15, alpha: 1.0),
        tabBarBackground: NSColor(white: 0.15, alpha: 1.0),
        activeTab: NSColor(white: 0.18, alpha: 1.0),
        inactiveTab: NSColor(white: 0.15, alpha: 1.0),
        activeTabText: NSColor(white: 0.90, alpha: 1.0),
        inactiveTabText: NSColor(white: 0.55, alpha: 1.0),
        toolbar: NSColor(white: 0.18, alpha: 1.0),
        toolbarText: NSColor(white: 0.50, alpha: 1.0),
        toolbarIconTint: NSColor(white: 0.60, alpha: 1.0),
        outline: NSColor(white: 0.13, alpha: 1.0),
        outlineText: NSColor(white: 0.90, alpha: 1.0),
        outlineSecondaryText: NSColor(white: 0.55, alpha: 1.0),
        outlineResizeHandle: NSColor(white: 0.18, alpha: 1.0),
        statusBar: NSColor(white: 0.18, alpha: 1.0),
        statusBarText: NSColor(white: 0.60, alpha: 1.0),
        statusBarIconTint: NSColor(white: 0.60, alpha: 1.0),
        accent: NSColor(red: 0.90, green: 0.55, blue: 0.20, alpha: 1.0)
    )

    static let ocean = ChromeScheme(
        name: "Ocean",
        titleBar: NSColor(red: 0.14, green: 0.20, blue: 0.28, alpha: 1.0),
        tabBarBackground: NSColor(red: 0.14, green: 0.20, blue: 0.28, alpha: 1.0),
        activeTab: NSColor(red: 0.17, green: 0.24, blue: 0.33, alpha: 1.0),
        inactiveTab: NSColor(red: 0.14, green: 0.20, blue: 0.28, alpha: 1.0),
        activeTabText: NSColor(red: 0.82, green: 0.90, blue: 0.97, alpha: 1.0),
        inactiveTabText: NSColor(red: 0.50, green: 0.60, blue: 0.70, alpha: 1.0),
        toolbar: NSColor(red: 0.17, green: 0.24, blue: 0.33, alpha: 1.0),
        toolbarText: NSColor(red: 0.45, green: 0.55, blue: 0.65, alpha: 1.0),
        toolbarIconTint: NSColor(red: 0.40, green: 0.65, blue: 0.80, alpha: 1.0),
        outline: NSColor(red: 0.12, green: 0.17, blue: 0.24, alpha: 1.0),
        outlineText: NSColor(red: 0.82, green: 0.90, blue: 0.97, alpha: 1.0),
        outlineSecondaryText: NSColor(red: 0.50, green: 0.60, blue: 0.70, alpha: 1.0),
        outlineResizeHandle: NSColor(red: 0.17, green: 0.24, blue: 0.33, alpha: 1.0),
        statusBar: NSColor(red: 0.17, green: 0.24, blue: 0.33, alpha: 1.0),
        statusBarText: NSColor(red: 0.50, green: 0.65, blue: 0.80, alpha: 1.0),
        statusBarIconTint: NSColor(red: 0.40, green: 0.65, blue: 0.80, alpha: 1.0),
        accent: NSColor(red: 0.35, green: 0.75, blue: 0.90, alpha: 1.0)
    )

    static let rose = ChromeScheme(
        name: "Rose",
        titleBar: NSColor(red: 0.26, green: 0.16, blue: 0.20, alpha: 1.0),
        tabBarBackground: NSColor(red: 0.26, green: 0.16, blue: 0.20, alpha: 1.0),
        activeTab: NSColor(red: 0.32, green: 0.20, blue: 0.25, alpha: 1.0),
        inactiveTab: NSColor(red: 0.26, green: 0.16, blue: 0.20, alpha: 1.0),
        activeTabText: NSColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0),
        inactiveTabText: NSColor(red: 0.65, green: 0.48, blue: 0.55, alpha: 1.0),
        toolbar: NSColor(red: 0.32, green: 0.20, blue: 0.25, alpha: 1.0),
        toolbarText: NSColor(red: 0.60, green: 0.45, blue: 0.50, alpha: 1.0),
        toolbarIconTint: NSColor(red: 0.80, green: 0.50, blue: 0.60, alpha: 1.0),
        outline: NSColor(red: 0.22, green: 0.14, blue: 0.17, alpha: 1.0),
        outlineText: NSColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0),
        outlineSecondaryText: NSColor(red: 0.65, green: 0.48, blue: 0.55, alpha: 1.0),
        outlineResizeHandle: NSColor(red: 0.32, green: 0.20, blue: 0.25, alpha: 1.0),
        statusBar: NSColor(red: 0.32, green: 0.20, blue: 0.25, alpha: 1.0),
        statusBarText: NSColor(red: 0.65, green: 0.50, blue: 0.58, alpha: 1.0),
        statusBarIconTint: NSColor(red: 0.80, green: 0.50, blue: 0.60, alpha: 1.0),
        accent: NSColor(red: 0.90, green: 0.45, blue: 0.55, alpha: 1.0)
    )

    static let forest = ChromeScheme(
        name: "Forest",
        titleBar: NSColor(red: 0.15, green: 0.22, blue: 0.16, alpha: 1.0),
        tabBarBackground: NSColor(red: 0.15, green: 0.22, blue: 0.16, alpha: 1.0),
        activeTab: NSColor(red: 0.19, green: 0.27, blue: 0.20, alpha: 1.0),
        inactiveTab: NSColor(red: 0.15, green: 0.22, blue: 0.16, alpha: 1.0),
        activeTabText: NSColor(red: 0.85, green: 0.93, blue: 0.85, alpha: 1.0),
        inactiveTabText: NSColor(red: 0.50, green: 0.62, blue: 0.50, alpha: 1.0),
        toolbar: NSColor(red: 0.19, green: 0.27, blue: 0.20, alpha: 1.0),
        toolbarText: NSColor(red: 0.48, green: 0.58, blue: 0.48, alpha: 1.0),
        toolbarIconTint: NSColor(red: 0.45, green: 0.70, blue: 0.45, alpha: 1.0),
        outline: NSColor(red: 0.12, green: 0.18, blue: 0.13, alpha: 1.0),
        outlineText: NSColor(red: 0.85, green: 0.93, blue: 0.85, alpha: 1.0),
        outlineSecondaryText: NSColor(red: 0.50, green: 0.62, blue: 0.50, alpha: 1.0),
        outlineResizeHandle: NSColor(red: 0.19, green: 0.27, blue: 0.20, alpha: 1.0),
        statusBar: NSColor(red: 0.19, green: 0.27, blue: 0.20, alpha: 1.0),
        statusBarText: NSColor(red: 0.50, green: 0.65, blue: 0.50, alpha: 1.0),
        statusBarIconTint: NSColor(red: 0.45, green: 0.70, blue: 0.45, alpha: 1.0),
        accent: NSColor(red: 0.50, green: 0.80, blue: 0.45, alpha: 1.0)
    )

    static let all: [ChromeScheme] = [light, dark, ocean, rose, forest]

    static var current: ChromeScheme {
        let name = UserDefaults.standard.string(forKey: "ChromeScheme") ?? "Light"
        return all.first(where: { $0.name == name }) ?? light
    }

    var isDark: Bool { name != "Light" }

    static let changedNotification = Notification.Name("ChromeSchemeChanged")
}
