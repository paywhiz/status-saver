import 'dart:io';

import 'status_item.dart';

/// Platform-agnostic interface for reading "recent" statuses (the live feed
/// from WhatsApp). Saved-tab data goes through [SavedStore] directly, not
/// here, because saved items are platform-independent.
abstract class StatusRepository {
  /// True when this repo is ready to list items (e.g. permissions granted /
  /// SAF folders picked).
  Future<bool> isReady();

  /// Initiate the platform-specific permission / setup flow.
  Future<bool> requestSetup();

  /// True when secondary (WhatsApp Business) access has been granted.
  Future<bool> hasSecondarySetup();

  /// Initiate the secondary (WhatsApp Business) folder setup flow.
  Future<bool> requestSecondarySetup();

  /// All recent statuses across Messenger + Business, newest first.
  Future<List<StatusItem>> listRecent();

  /// Read the bytes for a recent item so it can be copied into SavedStore
  /// or saved to the gallery.
  Future<List<int>> readBytes(StatusItem item);
}

/// No-op implementation used on iOS where there is no Recent feed.
class NullStatusRepository implements StatusRepository {
  @override
  Future<bool> isReady() async => true;

  @override
  Future<bool> requestSetup() async => true;

  @override
  Future<bool> hasSecondarySetup() async => true;

  @override
  Future<bool> requestSecondarySetup() async => true;

  @override
  Future<List<StatusItem>> listRecent() async => const [];

  @override
  Future<List<int>> readBytes(StatusItem item) async {
    final f = item.file;
    if (f != null) return f.readAsBytes();
    throw UnsupportedError('No file backing this item.');
  }
}

bool isAndroid() => Platform.isAndroid;
bool isIOS() => Platform.isIOS;
