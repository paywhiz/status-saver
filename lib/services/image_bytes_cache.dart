import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';

import '../data/status_item.dart';

/// In-memory LRU cache for image bytes — backs both grid thumbnails and the
/// fullscreen viewer. A single shared cache means a tile that's been seen in
/// the grid is "warm" when the user taps to open it, eliminating the reload
/// the user reported.
///
/// No on-disk layer: full-resolution status images at hundreds-of-entries
/// scale would balloon storage, and the underlying SAF / MediaStore reads
/// are fast enough that an in-memory LRU is sufficient. Concurrent loads
/// for the same key are de-duplicated via `_inflight`.
class ImageBytesCache {
  ImageBytesCache._();
  static final ImageBytesCache _instance = ImageBytesCache._();
  factory ImageBytesCache() => _instance;

  static const _channel = MethodChannel('com.example.status_saver/saf');
  static const _maxEntries = 96;

  final LinkedHashMap<String, Uint8List> _bytes =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List?>> _inflight = {};

  /// For grid tiles: returns null on read failure rather than throwing.
  Future<Uint8List?> forItemThumb(StatusItem item) => _get(item);

  /// For the fullscreen viewer: throws on read failure so the viewer can
  /// surface an error state.
  Future<Uint8List> forItemFull(StatusItem item) async {
    final bytes = await _get(item);
    if (bytes == null) {
      throw StateError(
        'Could not read bytes for ${item.displayName ?? item.id}',
      );
    }
    return bytes;
  }

  Future<Uint8List?> _get(StatusItem item) {
    final key = _key(item);
    if (key == null) return Future.value(null);

    final hit = _bytes[key];
    if (hit != null) {
      _bytes.remove(key);
      _bytes[key] = hit;
      return Future.value(hit);
    }
    final pending = _inflight[key];
    if (pending != null) return pending;

    final f = _readSource(item).then((bytes) {
      if (bytes != null) _put(key, bytes);
      return bytes;
    }).whenComplete(() => _inflight.remove(key));
    _inflight[key] = f;
    return f;
  }

  String? _key(StatusItem item) => item.uri ?? item.file?.path;

  Future<Uint8List?> _readSource(StatusItem item) async {
    final f = item.file;
    if (f != null) {
      try {
        return await f.readAsBytes();
      } catch (_) {
        return null;
      }
    }
    final uri = item.uri;
    if (uri == null) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('readBytes', {'uri': uri});
    } catch (_) {
      return null;
    }
  }

  void _put(String key, Uint8List bytes) {
    _bytes[key] = bytes;
    if (_bytes.length > _maxEntries) {
      _bytes.remove(_bytes.keys.first);
    }
  }
}
