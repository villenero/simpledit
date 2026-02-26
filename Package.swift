// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MDView",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MDView",
            path: "MDView",
            exclude: ["Resources/Info.plist", "Resources/Assets.xcassets"],
            resources: [
                .copy("Resources/icon.png"),
                .process("Markdown/Resources")
            ]
        ),
        .testTarget(
            name: "MDViewTests",
            dependencies: ["MDView"],
            path: "MDViewTests"
        )
    ]
)
