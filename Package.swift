// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EasyRelationship",
    platforms: [
        .iOS(.v16),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "EasyRelationshipCore",
            targets: ["EasyRelationshipCore"]
        )
    ],
    targets: [
        .target(
            name: "EasyRelationshipCore"
            ,
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .executableTarget(
            name: "EasyRelationshipCLISmoke",
            dependencies: ["EasyRelationshipCore"]
        )
    ]
)
