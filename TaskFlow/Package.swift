// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TaskFlowLib", targets: ["TaskFlowLib"]),
        .executable(name: "TaskFlow", targets: ["TaskFlow"]),
        .executable(name: "TestRunner", targets: ["TestRunner"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0")
    ],
    targets: [
        .target(
            name: "TaskFlowLib",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/TaskFlowLib"
        ),
        .executableTarget(
            name: "TaskFlow",
            dependencies: ["TaskFlowLib"],
            path: "Sources/TaskFlow"
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["TaskFlowLib"],
            path: "Sources/TestRunner"
        ),
        .testTarget(
            name: "TaskFlowTests",
            dependencies: ["TaskFlowLib"],
            path: "Tests/TaskFlowTests"
        )
    ]
)
