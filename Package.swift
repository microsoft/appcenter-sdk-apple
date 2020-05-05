// swift-tools-version:5.0

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import PackageDescription

let package = Package(
    name: "App Center",
    products: [
        .library(
            name: "AppCenterAnalytics",
            targets: ["AppCenterAnalytics"]),
        .library(
            name: "AppCenterCrashes",
            targets: ["AppCenterCrashes"])
    ],
    dependencies: [
        .package(url: "https://github.com/microsoft/plcrashreporter.git", .branch("feature/spm")),
    ],
    targets: [
        .target(
            name: "AppCenter",
            dependencies: [],
            path: "AppCenter/AppCenter",
            exclude: ["Support"],
            cSettings: [
                .define("APP_CENTER_C_NAME", to: "\"appcenter.ios\"", .when(platforms: [.iOS])),
                .define("APP_CENTER_C_NAME", to: "\"appcenter.macos\"", .when(platforms: [.macOS])),
                .define("APP_CENTER_C_NAME", to: "\"appcenter.tvos\"", .when(platforms: [.tvOS])),
                .define("APP_CENTER_C_VERSION", to:"\"3.1.1\""),
                .define("APP_CENTER_C_BUILD", to:"\"1\""),
                .headerSearchPath("**"),
            ],
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
            cSettings: [
                .headerSearchPath("**"),
                .headerSearchPath("../../AppCenter/AppCenter/**"),
            ],
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
            cSettings: [
                .headerSearchPath("**"),
                .headerSearchPath("../../AppCenter/AppCenter/**"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        )
    ]
)
