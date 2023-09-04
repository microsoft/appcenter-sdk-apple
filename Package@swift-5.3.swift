// swift-tools-version:5.3

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import PackageDescription

let projectHeaderSearchPaths = [
    "**",
    "../../AppCenter/AppCenter/Internals",
    "../../AppCenter/AppCenter/Internals/Channel",
    "../../AppCenter/AppCenter/Internals/Context/Device",
    "../../AppCenter/AppCenter/Internals/Context/Session",
    "../../AppCenter/AppCenter/Internals/Context/UserId",
    "../../AppCenter/AppCenter/Internals/DelegateForwarder",
    "../../AppCenter/AppCenter/Internals/HttpClient",
    "../../AppCenter/AppCenter/Internals/HttpClient/Util",
    "../../AppCenter/AppCenter/Internals/Ingestion",
    "../../AppCenter/AppCenter/Internals/Ingestion/Util",
    "../../AppCenter/AppCenter/Internals/Model",
    "../../AppCenter/AppCenter/Internals/Model/CommonSchema",
    "../../AppCenter/AppCenter/Internals/Model/Properties",
    "../../AppCenter/AppCenter/Internals/Model/Util",
    "../../AppCenter/AppCenter/Internals/Storage",
    "../../AppCenter/AppCenter/Internals/Util",
    "../../AppCenter/AppCenter/Internals/Vendor/Reachability",
    "../../AppCenter/AppCenter/include",
    "../../AppCenter/AppCenter/Model",
    "../../AppCenterAnalytics/AppCenterAnalytics/include",
    "../../AppCenterAnalytics/AppCenterAnalytics/Internals",
    "../../AppCenterAnalytics/AppCenterAnalytics/Internals/Model",
    "../../AppCenterAnalytics/AppCenterAnalytics/Internals/Session",
    "../../AppCenterAnalytics/AppCenterAnalytics/Internals/Util",
    "../../AppCenterAnalytics/AppCenterAnalytics/Model",
    "../../AppCenterAnalytics/AppCenterAnalytics/TransmissionTarget",
    "../../AppCenterCrashes/AppCenterCrashes/Internals",
    "../../AppCenterCrashes/AppCenterCrashes/Internals/Model",
    "../../AppCenterCrashes/AppCenterCrashes/Internals/Util",
    "../../AppCenterCrashes/AppCenterCrashes/include",
    "../../AppCenterCrashes/AppCenterCrashes/Model",
    "../../AppCenterCrashes/AppCenterCrashes/WrapperSDKUtilities",
    "../../AppCenterDistribute/AppCenterDistribute/Internals",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Channel",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Ingestion",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Model",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Version",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Util",
    "../../AppCenterDistribute/AppCenterDistribute/include",
    "../../AppCenterDistribute/AppCenterDistribute/Model"
]

let cHeaderSearchPaths: [CSetting] = projectHeaderSearchPaths.map { .headerSearchPath($0) }

let package = Package(
    name: "AppCenter",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "AppCenterAnalytics",
            targets: ["AppCenterAnalytics"]),
        .library(
            name: "AppCenterCrashes",
            targets: ["AppCenterCrashes"]),
        .library(
            name: "AppCenterDistribute",
            targets: ["AppCenterDistribute"]),
    ],
    dependencies: [
        .package(url: "https://github.com/microsoft/PLCrashReporter.git", .upToNextMinor(from: "1.11.0")),
    ],
    targets: [
        .target(
            name: "AppCenter",
            path: "AppCenter/AppCenter",
            exclude: ["Support"],
            cSettings: {
                var settings: [CSetting] = [
                    .define("APP_CENTER_C_VERSION", to:"\"5.0.3\""),
                    .define("APP_CENTER_C_BUILD", to: "\"1\"")
                ]
                settings.append(contentsOf: cHeaderSearchPaths)
                return settings
            }(),
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("Foundation"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "AppCenterAnalytics",
            dependencies: ["AppCenter"],
            path: "AppCenterAnalytics/AppCenterAnalytics",
            exclude: ["Support"],
            cSettings: cHeaderSearchPaths,
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        ),
        .target(
            name: "AppCenterCrashes",
            dependencies: [
                "AppCenter",
                .product(name: "CrashReporter", package: "PLCrashReporter"),
            ],
            path: "AppCenterCrashes/AppCenterCrashes",
            exclude: ["Support", "Internals/MSACCrashesBufferedLog.hpp"],
            cSettings: cHeaderSearchPaths,
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        ),
        .target(
            name: "AppCenterDistribute",
            dependencies: ["AppCenter"],
            path: "AppCenterDistribute/AppCenterDistribute",
            exclude: ["Support"],
            cSettings: cHeaderSearchPaths,
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("SafariServices", .when(platforms: [.iOS])),
                .linkedFramework("AuthenticationServices", .when(platforms: [.iOS])),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
            ]
        )
    ]
)
