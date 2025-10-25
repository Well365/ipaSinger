// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MacSigner",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacSigner", targets: ["MacSigner"])
    ],
    targets: [
        .executableTarget(
            name: "MacSigner",
            path: "Sources/MacSigner"
        )
    ]
)
