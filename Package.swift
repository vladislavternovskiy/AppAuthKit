// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppAuthKit",
    platforms: [.iOS(.v13), .macOS(.v11), .tvOS(.v13), .watchOS(.v7)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppAuthKit",
            targets: ["AppAuthKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppAuthKit",
            dependencies: [
                .product(name: "SimpleKeychain", package: "SimpleKeychain")
            ]
        ),
        .testTarget(
            name: "AppAuthKitTests",
            dependencies: ["AppAuthKit"]),
    ]
)
