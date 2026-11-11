// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VietKeyCore",
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(name: "VietKeyCore", targets: ["VietKeyCore"]),
    ],
    targets: [
        .target(name: "VietKeyCore", resources: [.process("Frequency/Data")]),
        .testTarget(name: "VietKeyCoreTests", dependencies: ["VietKeyCore"]),
    ]
)
