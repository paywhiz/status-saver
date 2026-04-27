import 'dart:async';
import 'dart:io';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'saved_store.dart';
import 'status_item.dart';

/// Bridges incoming media from the iOS Share Extension and the Files-app
/// importer into the [SavedStore]. Items are copied to app-private storage
/// the moment they arrive so the UI has a single source of truth.
class IosShareIngest {
  IosShareIngest(this._store);

  final SavedStore _store;
  StreamSubscription<List<SharedMediaFile>>? _sub;

  /// Call once at app start. Pulls in any media that opened the app and
  /// keeps listening for media that arrives while the app is running.
  Future<List<StatusItem>> attach() async {
    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    final ingested = await _ingest(initial);

    _sub?.cancel();
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(_ingest);

    return ingested;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<List<StatusItem>> _ingest(List<SharedMediaFile> files) async {
    final added = <StatusItem>[];
    for (final f in files) {
      final src = File(f.path);
      if (!await src.exists()) continue;
      final name = src.uri.pathSegments.last;
      final saved = await _store.saveFile(source: src, overrideName: name);
      added.add(saved);
    }
    if (added.isNotEmpty) {
      // Tell the framework we've consumed the inbound payload so it isn't
      // replayed on next cold start.
      ReceiveSharingIntent.instance.reset();
    }
    return added;
  }
}
