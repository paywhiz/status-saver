import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Best-effort permission helpers. Most heavy lifting is delegated to the
/// SAF picker on Android and to the Photos privacy prompt on iOS, which run
/// at the moment of first use.
class Permissions {
  /// On Android 13+, save-to-gallery for images can require READ_MEDIA_IMAGES
  /// when ImageGallerySaverPlus is used through MediaStore. On iOS, Photos
  /// add-only is requested by image_gallery_saver_plus on first save.
  Future<bool> ensureGallerySave() async {
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) {
      final s = await Permission.photos.request();
      if (s.isGranted || s.isLimited) return true;
      // Older Android falls back to storage.
      final fallback = await Permission.storage.request();
      return fallback.isGranted;
    }
    return true;
  }
}
