# iOS Share Extension setup

This directory contains the source for the Share Extension target. The
extension lets users tap **Share** in WhatsApp on a status, pick **Status
Saver**, and have the media land in the main app.

`flutter create .` does *not* generate Xcode share-extension targets, so
you have to wire them up manually in Xcode once. Steps:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Share Extension.** Name it `ShareExtension`.
   - Bundle id: e.g. `com.example.statusSaver.ShareExtension`
   - Embed in Runner.
3. Delete Xcode's generated `ShareViewController.swift`, `MainInterface.storyboard`,
   and `Info.plist` from the new target. Add the files in this folder
   (`ShareViewController.swift`, `Info.plist`, `ShareExtension.entitlements`)
   to the **ShareExtension** target instead. In `Info.plist`, remove the
   `NSExtensionMainStoryboard` key if Xcode added one — this extension is
   a `SLComposeServiceViewController` subclass and uses no storyboard.
4. **Signing & Capabilities** on both Runner and ShareExtension:
   - Add the **App Groups** capability with id `group.StatusSaverShareKey`
     (must match the value in `appGroupId` in `ShareViewController.swift`
     and the entitlements files in this repo).
   - Match the entitlements file to the one we ship: set
     `CODE_SIGN_ENTITLEMENTS = ShareExtension/ShareExtension.entitlements`
     in the ShareExtension target's build settings, and
     `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` on Runner.
5. **Runner Info.plist**: merge the keys from
   `ios/Runner/Info.plist.snippets.xml` (URL scheme + Photos usage strings).
6. Add the `receive_sharing_intent` Pod hooks per its README — primarily
   wiring `application(_:open:options:)` in `AppDelegate.swift` to forward
   the URL to the plugin.
7. Build & run on a real device. Open WhatsApp, tap a status, **Share →
   Status Saver**, return to the app — the file should appear in Saved.
