// swift-tools-version:6.0
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
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", "2.2.3" ..< "3.0.0"),
        .package(url: "https://github.com/kdeda/idd-swift.git", "2.4.8" ..< "3.0.0"),
        .package(url: "https://github.com/ra1028/DifferenceKit.git", exact: "1.3.0")

    ],
    targets: [
        .target(
            name: "IDDList",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "IDDSwift", package: "idd-swift"),
                .product(name: "DifferenceKit", package: "DifferenceKit")
            ]
        ),
        .testTarget(
            name: "IDDListTests",
            dependencies: [
                "IDDList",
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "IDDSwift", package: "idd-swift")
            ]
        )
    ]
)
