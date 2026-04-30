import 'dart:io';

import 'package:gal/gal.dart';

/// Best-effort permission helpers. Most heavy lifting is delegated to the
/// SAF picker on Android and to the Photos privacy prompt on iOS, which run
/// at the moment of first use.
class Permissions {
  /// Requests gallery write access (Photos add-only on iOS, MediaStore on
  /// Android). Asking for `toAlbum: true` ensures iOS also grants the
  /// permission needed to create / write into a custom album. Returns true
  /// when access is granted (or already granted).
  Future<bool> ensureGallerySave() async {
    // Non-mobile platforms have no gallery prompt — treat as a no-op.
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      if (await Gal.hasAccess(toAlbum: true)) return true;
      return await Gal.requestAccess(toAlbum: true);
    } catch (_) {
      return false;
    }
  }
}
