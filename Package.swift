// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Package.swift
import PackageDescription

/// IAB Distribution — umbrella package bundling the IABAds module and its
/// dependency closure as binary XCFrameworks.
///
/// Dependency closure (all DYNAMIC frameworks):
///   IABAds    -> Core, _Core, _FeedCore
///   GenuinSDK -> Core, _Core
///   _FeedCore -> Core, _Core
///   Core      -> _Core
///   _Core     -> (leaf)
///
/// Binary targets cannot declare dependencies on one another, so each product
/// below lists *every* xcframework it transitively needs.
///
/// NOTE: iOS-only — the Google IMA SDK used by IABAds does not support macOS.
/// NOTE: A binaryTarget cannot declare SPM dependencies. IABAds links the Google
///       IMA SDK (and nothing else from Google — GoogleMobileAds is NOT required),
///       so the consuming app must add it itself, e.g.:
///         .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios", branch:
/// "main")
///       and add the `GoogleInteractiveMediaAds` product to its app target.
let package = Package(
    name: "GenuinIAB",
    platforms: [.iOS(.v16)],
    products: [
        // MARK: - Products

        .library(
            name: "GenuinSDK",
            targets: ["GenuinSDK", "Core", "_Core"]
        ),
        .library(
            name: "IABAds",
            targets: ["IABAds", "_FeedCore", "Core", "_Core"]
        )
    ],
    targets: [
        // MARK: - Binary Targets

        .binaryTarget(
            name: "_Core",
            path: "_Core/_Core.xcframework"
        ),
        .binaryTarget(
            name: "Core",
            path: "Core/Core.xcframework"
        ),
        .binaryTarget(
            name: "_FeedCore",
            path: "_FeedCore/_FeedCore.xcframework"
        ),
        .binaryTarget(
            name: "IABAds",
            path: "IABAds/IABAds.xcframework"
        ),
        .binaryTarget(
            name: "GenuinSDK",
            path: "GenuinSDK/GenuinSDK.xcframework"
        )
    ]
)
