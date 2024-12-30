// swift-tools-version:5.7
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
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", "2.1.15" ..< "3.0.0"),
        .package(url: "https://github.com/kdeda/idd-swift.git", "2.3.5" ..< "3.0.0"),
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
