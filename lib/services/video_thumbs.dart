import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../data/status_item.dart';

/// Decodes a single video frame to use as a grid thumbnail. Bridges to the
/// `com.example.status_saver/saf` platform channel: Android uses
/// `MediaMetadataRetriever` (supports SAF content URIs and file paths); iOS
/// uses `AVAssetImageGenerator` (file paths only — saved items only).
class VideoThumbs {
  VideoThumbs._();
  static final VideoThumbs _instance = VideoThumbs._();
  factory VideoThumbs() => _instance;

  static const _channel = MethodChannel('com.example.status_saver/saf');
  static const _maxEntries = 128;

  final LinkedHashMap<String, Uint8List?> _cache =
      LinkedHashMap<String, Uint8List?>();
  final Map<String, Future<Uint8List?>> _inflight = {};

  Future<Uint8List?> forItem(StatusItem item) {
    final key = item.uri ?? item.file?.path;
    if (key == null) return Future.value(null);

    if (_cache.containsKey(key)) {
      // Touch for LRU.
      final v = _cache.remove(key);
      _cache[key] = v;
      return Future.value(v);
    }
    final pending = _inflight[key];
    if (pending != null) return pending;

    final f = _load(item).whenComplete(() => _inflight.remove(key));
    _inflight[key] = f;
    return f;
  }

  Future<Uint8List?> _load(StatusItem item) async {
    final key = item.uri ?? item.file?.path;
    if (key == null) return null;
    Uint8List? bytes;
    try {
      bytes = await _channel.invokeMethod<Uint8List>('videoThumbnail', {
        'uri': item.uri,
        'path': item.file?.path,
        'maxSize': 256,
      });
    } catch (_) {
      bytes = null;
    }
    _cache[key] = bytes;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return bytes;
  }
}
