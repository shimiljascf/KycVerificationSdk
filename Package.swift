// swift-tools-version:5.3

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
                .define("SWIFT_SUPPRESS_WARNINGS")
                // Removed the unsafe flags that were causing the error
            ]),
    ],
    swiftLanguageVersions: [.v5] // This specifies compatible Swift versions
)
