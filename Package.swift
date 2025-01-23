// swift-tools-version: 6.0
import PackageDescription

// GIT_VERSION=1.2.2 swift run toucan-serve --version
var gitVersion: String {
    if let version = Context.environment["GIT_VERSION"] {
        return version
    }
    guard let gitInfo = Context.gitInformation else {
        return "(untracked)"
    }
    let base = gitInfo.currentTag ?? gitInfo.currentCommit
    return gitInfo.hasUncommittedChanges ? "\(base) (modified)" : base
}

let package = Package(
    name: "toucan",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "ToucanSDK", targets: ["ToucanSDK"]),
        .executable(name: "toucan-cli", targets: ["toucan-cli"]),
        .executable(name: "toucan-generate", targets: ["toucan-generate"]),
        .executable(name: "toucan-init", targets: ["toucan-init"]),
        .executable(name: "toucan-serve", targets: ["toucan-serve"]),
        .executable(name: "toucan-watch", targets: ["toucan-watch"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-markdown", branch: "main"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/binarybirds/file-manager-kit", from: "0.1.0"),
        .package(url: "https://github.com/binarybirds/shell-kit", from: "1.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.2.0"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache", from: "2.0.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.1.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.7.0"),
    ],
    targets: [
        // MARK: - libraries
        .target(
            name: "libgitversion",
            cSettings: [
                .define("GIT_VERSION", to: #""\#(gitVersion)""#),
            ]
        ),
        .target(
            name: "GitVersion",
            dependencies: [
                .target(name: "libgitversion"),
            ]
        ),
        .target(
            name: "ToucanSDK",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ShellKit", package: "shell-kit"),
                .product(name: "FileManagerKit", package: "file-manager-kit"),
                .product(name: "Mustache", package: "swift-mustache"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Yams", package: "yams"),
            ]
        ),
        // MARK: - executables
        .executableTarget(
            name: "toucan-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "ToucanSDK"),
            ]
        ),
        .executableTarget(
            name: "toucan-generate",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "ToucanSDK"),
            ]
        ),
        .executableTarget(
            name: "toucan-init",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "ToucanSDK"),
            ]
        ),
        .executableTarget(
            name: "toucan-serve",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .target(name: "ToucanSDK"),
                .target(name: "GitVersion"),
            ]
        ),
        .executableTarget(
            name: "toucan-watch",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ShellKit", package: "shell-kit"),
                .target(name: "ToucanSDK"),
            ]
        ),
        // MARK: - tests
        .testTarget(
            name: "ToucanSDKTests",
            dependencies: [
                .target(name: "ToucanSDK"),
            ]
        )
    ]
)
