import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

   override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Enviar o caminho do arquivo PDF para o Flutter via MethodChannel
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "pdf_reader_channel", binaryMessenger: controller.binaryMessenger)
        
        channel.invokeMethod("getPdfPathIos", arguments: url.path)
        
        return true
    }
}
