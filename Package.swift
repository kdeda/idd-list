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
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", "2.0.1" ..< "3.0.0"),
    ],
    targets: [
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
