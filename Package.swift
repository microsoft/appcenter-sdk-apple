// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "App Center",
    products: [
        .library(
            name: "AppCenterAnalytics",
            targets: ["AppCenterAnalytics"]),
        .library(
            name: "AppCenterPush",
            targets: ["AppCenterPush"]),
    ],
    dependencies: [
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
                .linkedFramework("AppKit", .when(platforms: [.macOS]))
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS]))
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "AppCenterAnalytics",
            dependencies: ["AppCenter"],         
            path: "AppCenterAnalytics/AppCenterAnalytics",
            exclude: ["Support"],
            cSettings: [
                .headerSearchPath("**"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3"),
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS]))
            ]
        )
        .target(
            name: "AppCenterPush",
            dependencies: ["AppCenter"],         
            path: "AppCenterPush/AppCenterPush",
            exclude: ["Support"],
            cSettings: [
                .headerSearchPath("**"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3"),
                .linkedFramework("Foundation"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("AppKit", .when(platforms: [.macOS]))
            ]
        )
    ]
)
