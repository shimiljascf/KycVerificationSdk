// swift-tools-version:6.0

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
                // Only use one rule for the XIB file to avoid duplicates
                .process("view/vkyc/CFKycVerificationViewController.xib")
            ],
            swiftSettings: [
                .define("SWIFT_SUPPRESS_WARNINGS"),
                .define("SWIFT_PACKAGE")
            ]),
    ],
    swiftLanguageModes: [.v5]
)
