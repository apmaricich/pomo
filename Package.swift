// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pomo",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "pomo", targets: ["pomo"])
    ],
    targets: [
        .executableTarget(
            name: "pomo",
            path: "Sources/pomo"
        ),
        .testTarget(
            name: "pomoTests",
            dependencies: ["pomo"],
            path: "Tests/pomoTests"
        )
    ]
)
