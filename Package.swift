// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let macPackage = Target.binaryTarget(name: "VLCKit-binary", url: "https://github.com/tylerjonesio/vlckit-spm/releases/download/v0.0.1/VLCKit.xcframework.zip", checksum: "8eda0c00fa4d01e66f292dc67b9743653859466ee7fa0daa637e5f91c6e95f21")
let iOSPackage = Target.binaryTarget(name: "MobileVLCKit-binary", url: "https://github.com/tylerjonesio/vlckit-spm/releases/download/v0.0.1/MobileVLCKit.xcframework.zip", checksum: "730b5dcf98a3ce09cc9afd0aee16da76e96e46d9684da2a2b30eb0c33280d668")
let tvPackage = Target.binaryTarget(name: "TVVLCKit-binary", url: "https://github.com/tylerjonesio/vlckit-spm/releases/download/v0.0.1/TVVLCKit.xcframework.zip", checksum: "97ca877127a4cf85af9e3881118e0ca0c9a9bd3a40c87a5aee27d8e4736bdad4")

let package = Package(
    name: "vlckit-spm",
    products: [
        .library(
            name: "MobileVLCKit",
            type: .dynamic,
            targets: ["MobileVLCKit"]),
        .library(
            name: "VLCKit",
            type: .dynamic,
            targets: ["VLCKit"]),
        .library(
            name: "TVVLCKit",
            type: .dynamic,
            targets: ["TVVLCKit"]),
    ],
    dependencies: [],
    targets: [
        iOSPackage,
        .target(
            name: "MobileVLCKit",
            dependencies: [
                .byName(name: "MobileVLCKit-binary")
            ], linkerSettings: [
                .linkedFramework("QuartzCore"),
                .linkedFramework("CoreText"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Security"),
                .linkedFramework("CFNetwork"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("OpenGLES"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("VideoToolbox"),
                .linkedFramework("CoreMedia"),
                .linkedLibrary("c++"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv")
            ]),
        macPackage,
        .target(
            name: "VLCKit",
            dependencies: [
                .byName(name: "VLCKit-binary")
            ], linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedLibrary("iconv")
            ]),
        tvPackage,
        .target(
            name: "TVVLCKit",
            dependencies: [
                .byName(name: "TVVLCKit-binary")
            ], linkerSettings: [
                .linkedFramework("CoreText"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("OpenGLES"),
                .linkedFramework("VideoToolbox"),
                .linkedFramework("CoreMedia"),
                .linkedLibrary("c++"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv")
            ]),
    ]
)
