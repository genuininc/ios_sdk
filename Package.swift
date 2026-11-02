// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Package.swift
import PackageDescription

/// Genuin distribution — umbrella package bundling every public module
/// (feed, comments, profile, group, community, ad networks and the IAB / in-stream
/// ads) and its dependency closure as binary XCFrameworks. Built by `build.sh`.
///
/// Dependency closure (all DYNAMIC frameworks):
///   GenuinInStreamAds -> Core, _Core, _FeedCore
///   GenuinPangleAds   -> Core                 (NOT _FeedCore / _Core — see below)
///   GenuinMetaAds     -> Core                 (NOT _FeedCore; + FBAudienceNetwork, added by the app)
///   GenuinSDK -> Core, _Core
///   _FeedCore -> Core, _Core
///   _SocialCore -> Core, _FeedCore, GenuinFeed
///   GenuinComments -> Core, _Core, _FeedCore
///   GenuinProfile, GenuinCommunity -> Core, _Core, _FeedCore, _SocialCore
///   GenuinGroup -> the above plus GenuinFeed
///   Core      -> _Core
///   _Core     -> (leaf)
///
/// Binary targets cannot declare dependencies on one another, so each product
/// below lists *every* xcframework it transitively needs.
///
/// EVERY framework here is flat — none embeds another. App Store validation rejects
/// a framework containing a nested framework (ITMS-90206 "contains disallowed file
/// 'Frameworks'" / ITMS-90205 "contains disallowed nested bundles"), so the Xcode
/// targets' "Embed Frameworks" phases are stripped by `build.sh` and the shared
/// `_Core` must reach the app as its own product target instead. That is why `_Core`
/// appears in every product list below, including the two that link only `Core`:
/// omitting it would leave a host that adds just that product with no
/// `_Core.framework` in its bundle, and a dyld failure at launch.
///
/// NOTE: iOS-only — the Google IMA SDK used by GenuinInStreamAds does not support macOS.
/// NOTE: A binaryTarget cannot declare SPM dependencies. GenuinInStreamAds links the Google
///       IMA SDK (and nothing else from Google — GoogleMobileAds is NOT required),
///       so the consuming app must add it itself, e.g.:
///         .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios", branch:
/// "main")
///       and add the `GoogleInteractiveMediaAds` product to its app target.
///
/// NOTE: GenuinPangleAds is the opposite case and needs NO such companion package.
///       Pangle (PAGAdSDK) ships a STATIC xcframework, so it is absorbed whole into
///       GenuinPangleAds.framework at archive time. Adding the Pangle package to the
///       app would link the SDK twice — don't. `internal import PAGAdSDK` keeps every
///       Pangle type out of the public interface, so none is visible to consumers.
///
///       The app MUST still declare, in its own Info.plist:
///         - `SKAdNetworkItems` (Pangle's ad-network ids)
///         - `NSUserTrackingUsageDescription`
///       The SDK reads ATT status but never raises the prompt — that is the host's
///       call — so the string is only needed if the host chooses to prompt.
///
/// NOTE: GenuinGMAAds is the same case as GenuinPangleAds, NOT the same case as
///       GenuinInStreamAds — even though both vendor SDKs come from Google.
///       GoogleMobileAds ships a STATIC xcframework and is absorbed, so the app must
///       NOT add Google's package; GoogleInteractiveMediaAds is dynamic and the app
///       MUST. The app does have to declare `GADApplicationIdentifier` in its own
///       Info.plist — Google reads it at launch and cannot be told at runtime.
///
/// NOTE: GenuinMetaAds is the opposite case from both of the above, and the same case as
///       GoogleInteractiveMediaAds. FBAudienceNetwork ships a DYNAMIC framework, so it is
///       NOT absorbed and the app MUST add it itself, e.g.:
///         .package(url: "https://github.com/facebook/FBAudienceNetwork", exact: "6.22.1")
///       and add the `FBAudienceNetwork` product to its app target. Without it dyld
///       fails at launch. The app must also declare Meta's `SKAdNetworkItems`; see
///       `__Worker/docs/modules/genuin-meta-ads.md`.
///
/// NOTE: GenuinPangleAds is OPTIONAL. It registers itself into
///       `BGAdNetworkRegistry` from `BGPangleAds.module`; a host that omits the
///       product has no "pangle" entry and those waterfall candidates are skipped
///       silently. Hence a separate product rather than a dependency of another.
///
/// NOTE: It links Core (and _Core, for the DI protocols) and nothing else of ours.
///       The vendor-neutral ad-slot boundary — BGAdSlotKind, IExternalAdNetwork,
///       BGAdNetworkRegistry, BGAdNetworkCredentials — lives in Core precisely so this
///       module can be dropped next to GenuinFeed in the main distribution, where
///       _FeedCore is a private nested copy. BGAdNetworkRegistry is the one thing whose
///       identity MUST be shared: the network registers into it and the feed reads it
///       back, so a second copy means zero ads and nothing in the logs.
///
///       _Core is the opposite: it holds only the ISDKModule / ISDKRegistrar protocol
///       declarations, no state, so duplicate copies across images are harmless —
///       Swift resolves the `Any.Type` -> `ISDKModule.Type` cast across images.
///       Verified with a throwaway app carrying four separate _Core copies.
let package = Package(
    name: "Genuin",
    platforms: [.iOS(.v16)],
    products: [
        // MARK: - Products

        .library(
            name: "GenuinSDK",
            targets: ["GenuinSDK", "Core", "_Core"]
        ),
        .library(
            name: "GenuinFeed",
            targets: ["GenuinFeed", "_FeedCore", "Core", "_Core"]
        ),
        .library(
            name: "GenuinInStreamAds",
            targets: ["GenuinInStreamAds", "_FeedCore", "Core", "_Core"]
        ),
        .library(
            name: "GenuinPangleAds",
            targets: ["GenuinPangleAds", "Core", "_Core"]
        ),
        .library(
            name: "GenuinGMAAds",
            targets: ["GenuinGMAAds", "Core", "_Core"]
        ),
        .library(
            name: "GenuinMetaAds",
            targets: ["GenuinMetaAds", "Core", "_Core"]
        ),
        .library(
            name: "GenuinComments",
            targets: ["GenuinComments", "_FeedCore", "Core", "_Core"]
        ),
        .library(
            name: "GenuinProfile",
            targets: ["GenuinProfile", "_SocialCore", "GenuinFeed", "_FeedCore", "Core", "_Core"]
        ),
        .library(
            name: "GenuinGroup",
            targets: ["GenuinGroup", "_SocialCore", "GenuinFeed", "_FeedCore", "Core", "_Core"]
        ),
        .library(
            name: "GenuinCommunity",
            targets: ["GenuinCommunity", "_SocialCore", "GenuinFeed", "_FeedCore", "Core", "_Core"]
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
            name: "_SocialCore",
            path: "_SocialCore/_SocialCore.xcframework"
        ),
        .binaryTarget(
            name: "GenuinFeed",
            path: "GenuinFeed/GenuinFeed.xcframework"
        ),
        .binaryTarget(
            name: "GenuinInStreamAds",
            path: "GenuinInStreamAds/GenuinInStreamAds.xcframework"
        ),
        .binaryTarget(
            name: "GenuinPangleAds",
            path: "GenuinPangleAds/GenuinPangleAds.xcframework"
        ),
        .binaryTarget(
            name: "GenuinGMAAds",
            path: "GenuinGMAAds/GenuinGMAAds.xcframework"
        ),
        .binaryTarget(
            name: "GenuinMetaAds",
            path: "GenuinMetaAds/GenuinMetaAds.xcframework"
        ),
        .binaryTarget(
            name: "GenuinComments",
            path: "GenuinComments/GenuinComments.xcframework"
        ),
        .binaryTarget(
            name: "GenuinProfile",
            path: "GenuinProfile/GenuinProfile.xcframework"
        ),
        .binaryTarget(
            name: "GenuinGroup",
            path: "GenuinGroup/GenuinGroup.xcframework"
        ),
        .binaryTarget(
            name: "GenuinCommunity",
            path: "GenuinCommunity/GenuinCommunity.xcframework"
        ),
        .binaryTarget(
            name: "GenuinSDK",
            path: "GenuinSDK/GenuinSDK.xcframework"
        )
    ]
)
