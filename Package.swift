// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version:5.3  // Specify an older Swift version here

import PackageDescription

let package = Package(
    name: "KycVerificationSdk",
    platforms: [
        .iOS(.v13)  // Specify your minimum deployment target
    ],
    products: [
        .library(
            name: "KycVerificationSdk",
            targets: ["KycVerificationSdk"]),
    ],
    targets: [
        .target(
            name: "KycVerificationSdk",
            swiftSettings: [
                .define("SWIFT_SUPPRESS_WARNINGS"),
                // You can also explicitly set Swift version for the target
                .unsafeFlags(["-swift-version", "5.3"])
            ]),
    ],
    swiftLanguageVersions: [.v5] // This specifies compatible Swift versions
)
