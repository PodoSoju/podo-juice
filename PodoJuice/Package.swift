// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PodoJuice",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PodoJuice", targets: ["PodoJuice"])
    ],
    targets: [
        .executableTarget(
            name: "PodoJuice",
            path: "Sources/PodoJuice"
        )
    ]
)
