import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/saved_store.dart';
import '../data/status_item.dart';
import '../features/recent/recent_controller.dart';
import '../features/saved/saved_controller.dart';
import '../features/settings/settings_controller.dart';
import 'media_saver.dart';
import 'permissions.dart';

/// Saves [item] using either the user's default destination or [override] when
/// provided (e.g. from a long-press menu). Shows a snackbar with the outcome.
///
/// Reused by the viewer's action bar and by per-tile save buttons.
Future<void> saveStatusItem(
  BuildContext context,
  StatusItem item, {
  SaveDestination? override,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final settings = context.read<SettingsController>();
  final destination = override ?? settings.saveDestination;

  // Recent items have no real File; we read bytes through the repository.
  final recent = item.file == null ? context.read<RecentController>() : null;
  final savedCtrl = destination == SaveDestination.inApp
      ? context.read<SavedController>()
      : null;
  final store = destination == SaveDestination.inApp
      ? context.read<SavedStore>()
      : null;

  if (destination == SaveDestination.gallery) {
    final ok = await Permissions().ensureGallerySave();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Permission denied'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  }

  final Uint8List bytes;
  final f = item.file;
  if (f != null) {
    bytes = await f.readAsBytes();
  } else {
    final list = await recent!.readBytes(item);
    bytes = list is Uint8List ? list : Uint8List.fromList(list);
  }

  final String name = item.displayName ?? 'status';

  bool ok;
  if (destination == SaveDestination.gallery) {
    ok = await MediaSaver().saveBytesToGallery(
      bytes: bytes,
      name: name,
      kind: item.kind,
    );
  } else {
    try {
      await store!.saveBytes(name: name, bytes: bytes);
      await savedCtrl!.refresh();
      ok = true;
    } catch (_) {
      ok = false;
    }
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text(_message(ok, destination)),
      duration: const Duration(seconds: 2),
    ),
  );
}

String _message(bool ok, SaveDestination destination) {
  if (!ok) return 'Save failed';
  return destination == SaveDestination.gallery
      ? 'Added to gallery'
      : 'Saved to app';
}
