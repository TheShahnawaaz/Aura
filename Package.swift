// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Aura",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Aura",
            targets: ["Aura"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/terryso/open-agent-sdk-swift.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "Aura",
            dependencies: [
                .product(name: "OpenAgentSDK", package: "open-agent-sdk-swift")
            ],
            path: "Sources/Aura"
        ),
        .testTarget(
            name: "AuraTests",
            dependencies: [
                "Aura",
                .product(name: "OpenAgentSDK", package: "open-agent-sdk-swift")
            ],
            path: "Tests/AuraTests"
        )
    ]
)
