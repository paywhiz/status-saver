import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/status_item.dart';

/// Decodes a downsampled image preview for grid tiles. Bridges to the
/// `com.example.status_saver/saf` platform channel: Android uses
/// `BitmapFactory` with `inSampleSize` so multi-megapixel WhatsApp photos are
/// not loaded in full just to draw a 140-px tile. iOS goes through Dart's
/// `ui.instantiateImageCodec` with `targetWidth` set.
///
/// Results are cached in two layers:
///   * an in-memory LRU (fast path within a session), and
///   * a small on-disk cache under the app cache directory, so cold starts do
///     not pay the decode cost again for already-seen images.
class ImageThumbs {
  ImageThumbs._();
  static final ImageThumbs _instance = ImageThumbs._();
  factory ImageThumbs() => _instance;

  static const _channel = MethodChannel('com.example.status_saver/saf');
  static const _maxEntries = 256;
  static const _maxDiskEntries = 1000;
  static const _maxSize = 384;
  static const _diskDirName = 'image_thumbs';

  final LinkedHashMap<String, Uint8List?> _cache =
      LinkedHashMap<String, Uint8List?>();
  final Map<String, Future<Uint8List?>> _inflight = {};

  Future<Directory>? _diskDirFuture;
  bool _prunedThisSession = false;

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

    final f = _load(item, key).whenComplete(() => _inflight.remove(key));
    _inflight[key] = f;
    return f;
  }

  Future<Uint8List?> _load(StatusItem item, String key) async {
    final mtime = item.modified.millisecondsSinceEpoch;
    final fileName = '${_hashKey(key, mtime)}.bin';

    // Disk hit: skip the native decode entirely.
    final fromDisk = await _readDisk(fileName);
    if (fromDisk != null) {
      _put(key, fromDisk);
      _schedulePrune();
      return fromDisk;
    }

    final bytes = await _decode(item);
    _put(key, bytes);
    if (bytes != null) {
      unawaited(_writeDisk(fileName, bytes));
    }
    _schedulePrune();
    return bytes;
  }

  Future<Uint8List?> _decode(StatusItem item) async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<Uint8List>('imageThumbnail', {
          'uri': item.uri,
          'path': item.file?.path,
          'maxSize': _maxSize,
        });
      } catch (_) {
        return null;
      }
    }
    // iOS / fallback: load via Dart codec, downsampled to maxSize.
    final f = item.file;
    if (f == null) return null;
    try {
      final raw = await f.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        raw,
        targetWidth: _maxSize,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _put(String key, Uint8List? bytes) {
    _cache[key] = bytes;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<Directory> _diskDir() {
    return _diskDirFuture ??= () async {
      final base = await getApplicationCacheDirectory();
      final dir = Directory('${base.path}/$_diskDirName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }();
  }

  Future<Uint8List?> _readDisk(String fileName) async {
    try {
      final dir = await _diskDir();
      final f = File('${dir.path}/$fileName');
      if (!await f.exists()) return null;
      final bytes = await f.readAsBytes();
      // Touch mtime so LRU pruning treats this as recently used.
      try {
        f.setLastModifiedSync(DateTime.now());
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(String fileName, Uint8List bytes) async {
    try {
      final dir = await _diskDir();
      final tmp = File('${dir.path}/$fileName.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename('${dir.path}/$fileName');
    } catch (_) {
      // Cache writes are best-effort.
    }
  }

  void _schedulePrune() {
    if (_prunedThisSession) return;
    _prunedThisSession = true;
    unawaited(_prune());
  }

  Future<void> _prune() async {
    try {
      final dir = await _diskDir();
      final files = await dir
          .list(followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();
      if (files.length <= _maxDiskEntries) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      final excess = files.length - _maxDiskEntries;
      for (var i = 0; i < excess; i++) {
        try {
          await files[i].delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// 64-bit FNV-1a of `<key>|<mtime>` rendered as 16 hex chars. Including
  /// mtime ensures stale entries don't shadow updated source files.
  String _hashKey(String key, int mtime) {
    const fnvOffset = 0xcbf29ce484222325;
    const fnvPrime = 0x100000001b3;
    const mask64 = 0xFFFFFFFFFFFFFFFF;
    var h = fnvOffset;
    final raw = '$key|$mtime';
    for (var i = 0; i < raw.length; i++) {
      h ^= raw.codeUnitAt(i);
      h = (h * fnvPrime) & mask64;
    }
    return h.toRadixString(16).padLeft(16, '0');
  }
}
