# Status Saver

A free, ad-free, no-IAP **WhatsApp Status Saver** for Android and iOS,
supporting both **WhatsApp Messenger** and **WhatsApp Business**.

Built with Flutter. MIT licensed.

## Features (v1)

- View recent WhatsApp / WhatsApp Business statuses (Android)
- Receive statuses via the system Share sheet (iOS)
- Import media from Files (iOS)
- Full-screen image viewer with pinch-zoom
- Inline video playback
- Save to in-app Saved tab (app-private storage)
- Save to device gallery / Photos
- Share to other apps
- Delete from Saved

The following are **not** in v1 and are planned for later:
repost-to-WhatsApp, background auto-save, dark mode toggle, multi-select bulk
operations, text-status saver, direct-chat-without-saving-contact.

## Why is iOS different from Android?

iOS sandboxes every app's storage, so no third-party app — including this one
— can read WhatsApp's `.Statuses` directory directly. Every legitimate iOS
status saver therefore works the same way: through the system **Share** sheet.
The flow is:

1. Open WhatsApp → tap a contact's status.
2. Tap the ⋯ menu → **Share** → choose **Status Saver**.
3. The file is copied into the app's container; open Status Saver to see it
   in the **Saved** tab.

Android has no such restriction; the app reads the live `.Statuses` folder
through the Storage Access Framework after a one-time grant.

## Project layout

```
lib/                   # All Dart source
android/app/src/main/  # AndroidManifest with WhatsApp queries + media perms
ios/Runner/            # Main app entitlements + Info.plist additions
ios/ShareExtension/    # iOS share extension target source
```

See `ios/ShareExtension/README.md` for the one-time Xcode wiring of the
share extension.

## Building

This repo contains the source only. Run `flutter create` once to generate
the platform scaffolding (Gradle wrapper, Xcode project, etc.); existing
files in `android/`, `ios/`, `lib/` and the root will be left alone.

```bash
# 1. Install Flutter (>= 3.22)  -> https://docs.flutter.dev/get-started/install
flutter --version

# 2. Generate the platform scaffolding without overwriting our sources.
flutter create --org com.example --project-name status_saver \
    --platforms=android,ios .

# 3. Pull deps.
flutter pub get

# 4. Run on a connected device.
flutter run
```

After step 2, merge the iOS Info.plist additions from
`ios/Runner/Info.plist.snippets.xml` into `ios/Runner/Info.plist`, then
follow `ios/ShareExtension/README.md` to add the share-extension target in
Xcode and enable App Groups on both targets.

### Android notes

- On first run the app shows an onboarding screen and asks you to grant
  read access to:
  `Android/media/com.whatsapp/WhatsApp/Media/.Statuses`
  Optionally also:
  `Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses`
- The grant is persisted via `takePersistableUriPermission`, so it
  survives reboots. If a user revokes it from system settings, the
  onboarding screen reappears.
- We do **not** request `MANAGE_EXTERNAL_STORAGE` (Play Store would reject
  the app).

### iOS notes

- Target: iOS 14+ (UTType-based extension activation rule).
- The Share Extension and main app must share an **App Group** with id
  `group.StatusSaverShareKey`. If you change it, update both
  `ios/Runner/Runner.entitlements`,
  `ios/ShareExtension/ShareExtension.entitlements`, and the `appGroupId`
  constant at the top of `ShareExtension/ShareViewController.swift`.

## Verification (manual)

**Android (real device, Android 11+):**

1. Install WhatsApp + WhatsApp Business; view a few statuses so the
   `.Statuses` folder populates.
2. `flutter run` — walk through onboarding, grant SAF access.
3. Recent tab shows merged thumbnails newest-first; Images / Videos sub-tabs
   filter correctly.
4. Open an image → **Save** → it appears in the Saved tab.
   **Gallery** → it appears in Photos/Gallery.
   **Share** → opens system share sheet.
5. Open a video → it plays inline; same actions work.
6. Revoke SAF permission in system settings → app returns to the
   onboarding screen cleanly on next launch.

**iOS (real device — Simulator can't host WhatsApp):**

1. Build and install via Xcode (Runner + ShareExtension).
2. In WhatsApp: view a status → ⋯ → **Share** → **Status Saver**.
3. Return to the app → the file appears in the Saved tab.
4. **Gallery** → file appears in Photos.
5. **+ Import** → pick from Files → it appears in Saved.
6. **Share** and **Delete** work for both image and video items.

## Contributing

PRs welcome. Please run `flutter analyze` and keep the v1 promise: free,
no ads, no IAP. Any feature that requires a network call needs justification
in the PR description.

## License

MIT — see [LICENSE](LICENSE).

## Trademarks

WhatsApp is a trademark of Meta Platforms, Inc. This project is not
affiliated with or endorsed by WhatsApp or Meta.
