// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "KycVerificationSdk",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "KycVerificationSdk",
            targets: ["KycVerificationSdk"]),
    ],
    targets: [
        .target(
            name: "KycVerificationSdk",
            resources: [
                // Include all XIB files
                .process("**/*.xib"),
                // And also include any storyboard files
                .process("**/*.storyboard")
            ],
            swiftSettings: [
                .define("SWIFT_SUPPRESS_WARNINGS")
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
