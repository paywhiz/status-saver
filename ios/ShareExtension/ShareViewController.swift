//
//  ShareViewController.swift
//  Status Saver Share Extension
//
//  Receives images / videos from the system share sheet (e.g. shared from
//  WhatsApp's "Share status") and writes them into the app group container
//  shared with the main Runner target. The main app reads from there via
//  receive_sharing_intent on next launch / resume.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

private let appGroupId = "group.StatusSaverShareKey"
private let hostAppBundleId = "com.example.statusSaver" // override in build settings if needed
private let hostUrlScheme  = "StatusSaverShareKey"

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool { return true }

    override func didSelectPost() {
        guard let extensionContext = self.extensionContext else {
            completeRequest()
            return
        }

        let group = DispatchGroup()
        var savedFiles: [[String: String]] = []

        for inputItem in extensionContext.inputItems {
            guard let item = inputItem as? NSExtensionItem,
                  let attachments = item.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    handle(provider: provider, type: UTType.movie.identifier) { entry in
                        if let entry = entry { savedFiles.append(entry) }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    handle(provider: provider, type: UTType.image.identifier) { entry in
                        if let entry = entry { savedFiles.append(entry) }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.persistManifest(savedFiles)
            self?.openHostApp()
            self?.completeRequest()
        }
    }

    override func configurationItems() -> [Any]! { return [] }

    // MARK: - Private

    private func handle(provider: NSItemProvider,
                        type: String,
                        completion: @escaping ([String: String]?) -> Void) {
        provider.loadItem(forTypeIdentifier: type, options: nil) { (data, error) in
            guard error == nil else { completion(nil); return }

            var sourceURL: URL?
            if let url = data as? URL {
                sourceURL = url
            } else if let image = data as? UIImage {
                if let png = image.pngData() {
                    let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).png")
                    try? png.write(to: tmp)
                    sourceURL = tmp
                }
            } else if let imageData = data as? Data {
                let tmp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).bin")
                try? imageData.write(to: tmp)
                sourceURL = tmp
            }

            guard let src = sourceURL else { completion(nil); return }

            guard let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
            else { completion(nil); return }

            let inboxURL = containerURL.appendingPathComponent("inbox", isDirectory: true)
            try? FileManager.default.createDirectory(
                at: inboxURL, withIntermediateDirectories: true)

            let destURL = inboxURL.appendingPathComponent(
                "\(Int(Date().timeIntervalSince1970 * 1000))_\(src.lastPathComponent)")

            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: src, to: destURL)
            } catch {
                completion(nil); return
            }

            let kind = (type == UTType.movie.identifier) ? "video" : "image"
            completion(["path": destURL.path, "type": kind])
        }
    }

    private func persistManifest(_ files: [[String: String]]) {
        guard !files.isEmpty,
              let defaults = UserDefaults(suiteName: appGroupId) else { return }
        var existing = defaults.array(forKey: "ShareMedia") as? [[String: String]] ?? []
        existing.append(contentsOf: files)
        defaults.set(existing, forKey: "ShareMedia")
    }

    private func openHostApp() {
        guard let url = URL(string: "\(hostUrlScheme)://") else { return }
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.perform(#selector(UIApplication.open(_:options:completionHandler:)),
                            with: url, with: nil)
                return
            }
            responder = r.next
        }
    }

    private func completeRequest() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
