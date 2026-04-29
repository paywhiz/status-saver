import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.example.status_saver/saf",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "videoThumbnail" {
        let args = call.arguments as? [String: Any]
        let path = args?["path"] as? String
        let maxSize = (args?["maxSize"] as? Int) ?? 256
        DispatchQueue.global(qos: .userInitiated).async {
          let data = self.extractThumbnail(path: path, maxSize: maxSize)
          DispatchQueue.main.async { result(data) }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func extractThumbnail(path: String?, maxSize: Int) -> FlutterStandardTypedData? {
    guard let path = path else { return nil }
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    let gen = AVAssetImageGenerator(asset: asset)
    gen.appliesPreferredTrackTransform = true
    gen.maximumSize = CGSize(width: maxSize, height: maxSize)
    let time = CMTime(seconds: 0.1, preferredTimescale: 600)
    do {
      let cg = try gen.copyCGImage(at: time, actualTime: nil)
      let img = UIImage(cgImage: cg)
      guard let jpeg = img.jpegData(compressionQuality: 0.7) else { return nil }
      return FlutterStandardTypedData(bytes: jpeg)
    } catch {
      return nil
    }
  }
}
