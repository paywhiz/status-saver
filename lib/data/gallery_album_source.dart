import 'dart:io';

import 'package:flutter/services.dart';

import '../services/media_saver.dart';
import 'status_item.dart';

/// Reads the app-owned "Status Saver" album from MediaStore on Android. Used
/// by the Saved tab when the user's destination is the device gallery.
///
/// iOS is unsupported here — `gal` saves to a Photos album the app cannot
/// re-enumerate without additional plugins.
class GalleryAlbumSource {
  static const _channel = MethodChannel('com.example.status_saver/saf');

  Future<List<StatusItem>> list() async {
    if (!Platform.isAndroid) return const [];
    final List<dynamic>? raw;
    try {
      raw = await _channel.invokeMethod<List<dynamic>>('listGalleryAlbum', {
        'albumName': MediaSaver.albumName,
      });
    } catch (_) {
      return const [];
    }
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map(_toItem)
        .whereType<StatusItem>()
        .toList(growable: false);
  }

  /// Removes the underlying MediaStore row for [item]. On Android 11+ this
  /// surfaces a system confirmation dialog before deleting; the future
  /// resolves to true if the user confirmed and the row was removed.
  Future<bool> delete(StatusItem item) async {
    if (!Platform.isAndroid) return false;
    final uri = item.uri;
    if (uri == null) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'deleteGalleryItem',
        {'uri': uri},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  StatusItem? _toItem(Map row) {
    final uri = row['uri'] as String?;
    final name = row['name'] as String?;
    final kindStr = row['kind'] as String?;
    final modifiedMs = row['modifiedMs'];
    if (uri == null || name == null) return null;
    final kind =
        kindStr == 'video' ? StatusKind.video : StatusKind.image;
    final modified = DateTime.fromMillisecondsSinceEpoch(
      modifiedMs is int ? modifiedMs : 0,
    );
    return StatusItem(
      id: uri,
      kind: kind,
      origin: StatusOrigin.imported,
      modified: modified,
      uri: uri,
      displayName: name,
    );
  }
}
