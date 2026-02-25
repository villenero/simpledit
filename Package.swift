// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleEdit",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SimpleEdit",
            path: "SimpleEdit",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Markdown/Resources")
            ]
        ),
        .testTarget(
            name: "SimpleEditTests",
            dependencies: ["SimpleEdit"],
            path: "SimpleEditTests"
        )
    ]
)
