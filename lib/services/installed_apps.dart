import 'dart:io';

import 'package:flutter/services.dart';

/// Thin probe over the native package manager to ask whether a given
/// application package is installed. Used during onboarding so we can disable
/// WhatsApp variants the user doesn't actually have.
///
/// `<queries>` in `AndroidManifest.xml` already lists `com.whatsapp` and
/// `com.whatsapp.w4b`, which is required for `getPackageInfo` to see them on
/// Android 11+.
class InstalledApps {
  static const _channel = MethodChannel('com.example.status_saver/saf');

  Future<bool> isInstalled(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'package': packageName},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasWhatsApp() => isInstalled('com.whatsapp');

  Future<bool> hasWhatsAppBusiness() => isInstalled('com.whatsapp.w4b');
}
