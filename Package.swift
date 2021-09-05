// swift-tools-version:5.4
import PackageDescription
import Foundation

let package = Package(
    name: "Store",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .library(name: "Store", targets: ["Store"]),
    ],
    targets: [
        .target(name: "Store", path: "source", exclude: ["Test", "Testing"])
    ],
    swiftLanguageVersions: [.v5]
)
