import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/status_item.dart';
import '../features/recent/recent_controller.dart';
import 'media_saver.dart';
import 'permissions.dart';

/// Saves [item] to the device's photo gallery and shows a snackbar with the
/// outcome. Reused by the viewer's action bar and by per-tile download
/// buttons in the Recent / Saved grids.
Future<void> downloadStatusItemToGallery(
  BuildContext context,
  StatusItem item,
) async {
  final messenger = ScaffoldMessenger.of(context);
  // Recent items have no real File; we read bytes through the repository.
  final recent =
      item.file == null ? context.read<RecentController>() : null;

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

  Uint8List bytes;
  final f = item.file;
  if (f != null) {
    bytes = await f.readAsBytes();
  } else {
    final list = await recent!.readBytes(item);
    bytes = list is Uint8List ? list : Uint8List.fromList(list);
  }

  final saved = await MediaSaver().saveBytesToGallery(
    bytes: bytes,
    name: item.displayName ?? 'status',
    kind: item.kind,
  );
  messenger.showSnackBar(
    SnackBar(
      content: Text(saved ? 'Added to gallery' : 'Save failed'),
      duration: const Duration(seconds: 2),
    ),
  );
}
