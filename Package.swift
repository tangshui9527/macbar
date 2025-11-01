// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "MacBar",
            targets: ["MacBar"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .executableTarget(
            name: "MacBar",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-warn-long-function-bodies=100"]), // Warn about functions that take a long time to type-check
                .unsafeFlags(["-Xfrontend", "-warn-long-expression-type-checking=100"]) // Warn about expressions that take a long time to type-check
            ]
        )
    ]
)