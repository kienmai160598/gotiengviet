// swift-tools-version: 6.2
import PackageDescription

// Build the binary target first with Tools/build-grammar.sh.
let package = Package(
    name: "VietKeyGrammar",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "VietKeyGrammar", targets: ["VietKeyGrammar"]),
    ],
    targets: [
        .binaryTarget(name: "vietkey_grammarFFI", path: "build/VietKeyGrammarFFI.xcframework"),
        .target(name: "VietKeyGrammar", dependencies: ["vietkey_grammarFFI"]),
        .testTarget(name: "VietKeyGrammarTests", dependencies: ["VietKeyGrammar"]),
    ]
)
