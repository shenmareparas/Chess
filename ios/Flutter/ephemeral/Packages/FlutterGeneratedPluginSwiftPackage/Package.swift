// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.3"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-5.1.1"),
        .package(name: "fluttertoast", path: "../.packages/fluttertoast-10.0.2"),
        .package(name: "games_services", path: "../.packages/games_services-5.3.0"),
        .package(name: "in_app_purchase_storekit", path: "../.packages/in_app_purchase_storekit-0.4.17"),
        .package(name: "in_app_review", path: "../.packages/in_app_review-2.0.12"),
        .package(name: "multistockfish_chess", path: "../.packages/multistockfish_chess-0.6.0"),
        .package(name: "multistockfish_light", path: "../.packages/multistockfish_light-0.1.0"),
        .package(name: "multistockfish_variant", path: "../.packages/multistockfish_variant-0.4.0"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.6.2"),
        .package(name: "sound_effect", path: "../.packages/sound_effect-0.2.0"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.2"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview"),
        .package(name: "google_mobile_ads", path: "../.packages/google_mobile_ads-9.2.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "fluttertoast", package: "fluttertoast"),
                .product(name: "games-services", package: "games_services"),
                .product(name: "in-app-purchase-storekit", package: "in_app_purchase_storekit"),
                .product(name: "in-app-review", package: "in_app_review"),
                .product(name: "multistockfish-chess", package: "multistockfish_chess"),
                .product(name: "multistockfish-light", package: "multistockfish_light"),
                .product(name: "multistockfish-variant", package: "multistockfish_variant"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sound-effect", package: "sound_effect"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "google-mobile-ads", package: "google_mobile_ads"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
