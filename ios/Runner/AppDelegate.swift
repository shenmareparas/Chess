import Flutter
import UIKit

@_silgen_name("stockfish_light_init")
private func stockfish_light_init() -> Int32

private let _stockfishLightLinkHook: UnsafeRawPointer = {
  let fn: @convention(c) () -> Int32 = stockfish_light_init
  return unsafeBitCast(fn, to: UnsafeRawPointer.self)
}()

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Prevent linker dead-stripping of multistockfish_light in static CocoaPods builds
    _ = _stockfishLightLinkHook
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
