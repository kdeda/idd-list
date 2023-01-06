// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-list",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "IDDList",
            targets: ["IDDList"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", from: "1.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IDDList",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift")
            ]
        ),
        .testTarget(
            name: "IDDListTests",
            dependencies: [
                "IDDList",
                .product(name: "Log4swift", package: "idd-log4-swift")
            ]
        )
    ]
)
