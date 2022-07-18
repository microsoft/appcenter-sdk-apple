// swift-tools-version:5.0

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
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Model",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Version",
    "../../AppCenterDistribute/AppCenterDistribute/Internals/Util",
    "../../AppCenterDistribute/AppCenterDistribute/include",
    "../../AppCenterDistribute/AppCenterDistribute/Model"
]

let cHeaderSearchPaths: [CSetting] = projectHeaderSearchPaths.map { .headerSearchPath($0) }

let package = Package(
    name: "AppCenter",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "AppCenterAnalytics",
            type: .static,
            targets: ["AppCenterAnalytics"]),
        .library(
            name: "AppCenterCrashes",
            type: .static,
            targets: ["AppCenterCrashes"])
    ],
    dependencies: [
        .package(url: "https://github.com/microsoft/plcrashreporter.git", .upToNextMinor(from: "1.10.2")),
    ],
    targets: [
        .target(
            name: "AppCenter",
            path: "AppCenter/AppCenter",
            exclude: ["Support"],
            cSettings: {
                var settings: [CSetting] = [
                    .define("APP_CENTER_C_VERSION", to: "\"4.4.3\""),
                    .define("APP_CENTER_C_BUILD", to: "\"1\"")
                ]
                settings.append(contentsOf: cHeaderSearchPaths)
                return settings
            }(),
            linkerSettings: [
                .linkedLibrary("z"),
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
            dependencies: ["AppCenter", "CrashReporter"],
            path: "AppCenterCrashes/AppCenterCrashes",
            exclude: ["Support"],
            cSettings: cHeaderSearchPaths,
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        )
    ]
)
