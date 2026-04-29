import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/status_item.dart';

/// Decodes a single video frame to use as a grid thumbnail. Bridges to the
/// `com.example.status_saver/saf` platform channel: Android uses
/// `MediaMetadataRetriever` (supports SAF content URIs and file paths); iOS
/// uses `AVAssetImageGenerator` (file paths only — saved items only).
///
/// Results are cached in two layers:
///   * an in-memory LRU (fast path within a session), and
///   * a small on-disk cache under the app cache directory, so cold starts do
///     not pay the native decode cost again for already-seen videos.
class VideoThumbs {
  VideoThumbs._();
  static final VideoThumbs _instance = VideoThumbs._();
  factory VideoThumbs() => _instance;

  static const _channel = MethodChannel('com.example.status_saver/saf');
  static const _maxEntries = 128;
  static const _maxDiskEntries = 500;
  static const _diskDirName = 'video_thumbs';

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
    _put(key, bytes);
    if (bytes != null) {
      unawaited(_writeDisk(fileName, bytes));
    }
    _schedulePrune();
    return bytes;
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

  /// 64-bit FNV-1a of "<key>|<mtime>" rendered as 16 hex chars. Collisions are
  /// astronomically unlikely for the cache sizes we deal with, and including
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
