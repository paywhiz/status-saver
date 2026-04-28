# Releasing

Status Saver ships as Android APKs attached to GitHub Releases. Builds run on
GitHub Actions, so you don't need a local Flutter install to produce a
distributable APK.

## TL;DR

```bash
git tag v0.1.0
git push origin v0.1.0
```

Pushing a tag matching `v*` triggers `.github/workflows/release-apk.yml`, which
builds release APKs and attaches them to a freshly-created GitHub Release for
that tag.

## What the workflow produces

For every build, four APKs are uploaded:

| File | Use |
| --- | --- |
| `status-saver-<ref>-<sha>-universal.apk` | One APK that runs on any device. ~40 MB. |
| `status-saver-<ref>-<sha>-arm64-v8a.apk` | Modern phones (most devices since ~2017). ~15 MB. |
| `status-saver-<ref>-<sha>-armeabi-v7a.apk` | Older 32-bit ARM devices. ~14 MB. |
| `status-saver-<ref>-<sha>-x86_64.apk` | Emulators and rare x86 tablets. ~16 MB. |

`<ref>` is the tag name on tag pushes (e.g. `v0.1.0`) or the branch name on
manual runs. `<sha>` is the short commit SHA.

## Two ways to trigger a build

### 1. Tag a release (recommended for distribution)

Cut a release from any branch:

```bash
git tag v0.1.0      # follow semver: vMAJOR.MINOR.PATCH
git push origin v0.1.0
```

The workflow:

1. Builds the universal APK and the three per-ABI APKs.
2. Uploads them as workflow artifacts (downloadable from the run page for 30 days).
3. Creates a GitHub Release at `https://github.com/paywhiz/Status-Saver/releases/tag/v0.1.0`
   with the four APKs attached and auto-generated release notes (commit
   list since the previous tag).

### 2. Manual dispatch (for ad-hoc test builds)

Useful when you want an APK off a feature branch without cutting a release.

1. Open `https://github.com/paywhiz/Status-Saver/actions/workflows/release-apk.yml`.
2. Click **Run workflow**, pick the branch, click the green **Run workflow** button.
3. When the run completes (~5 min), open it and download the
   `status-saver-apks` artifact from the **Artifacts** section. It's a zip
   containing all four APKs.

Manual runs do **not** create a GitHub Release — they only upload artifacts.

## Installing on a phone

Open the release page on your phone's browser, tap the APK matching your
device's CPU (or just grab the `universal` one if unsure), and let Android
install it. You'll get a "Install unknown apps" prompt the first time —
accept for your browser.

To check your phone's CPU architecture:

```
Settings → About phone → look for "arm64" / "armeabi" / "x86_64"
```

Or just install `universal`.

## Local builds (optional)

If you do have Flutter installed locally:

```bash
flutter clean
flutter build apk --release                 # universal
flutter build apk --release --split-per-abi # per-ABI splits
```

Outputs land under `build/app/outputs/flutter-apk/`. `build/` is gitignored.

## Signing — current state

The release build is currently signed with the **debug keystore**
(`android/app/build.gradle.kts:37`). This is fine for sideloading and works
on every Android phone, but:

- Each developer's machine produces APKs signed with a different debug key,
  so updates between machines look like a different app to Android (the user
  has to uninstall first).
- The Play Store will reject debug-signed APKs.

To switch to a real signing config:

1. Generate a keystore once and keep it safe:
   ```bash
   keytool -genkey -v -keystore status-saver-release.keystore \
     -keyalg RSA -keysize 2048 -validity 10000 -alias status-saver
   ```
2. Add a release `signingConfig` to `android/app/build.gradle.kts` that reads
   the keystore path/password from environment variables.
3. Store the keystore file (base64-encoded) and its passwords as repository
   secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`,
   `KEY_PASSWORD`) and decode it in the workflow before `flutter build apk`.

This is a one-time setup; ask before doing it because losing the keystore
locks you out of updating the app on the Play Store forever.

## Versioning

`pubspec.yaml` has `version: 0.1.0+1`. The part before `+` is the user-facing
`versionName`; the part after is the integer `versionCode` (Android requires
this to increase monotonically across uploaded builds). Bump both before
tagging:

```yaml
version: 0.2.0+2
```

```bash
git commit -am "chore: bump version to 0.2.0"
git tag v0.2.0
git push origin main v0.2.0
```
