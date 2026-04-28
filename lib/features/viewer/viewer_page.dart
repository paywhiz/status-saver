import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../../services/media_saver.dart';
import '../../services/permissions.dart';
import '../../services/share_service.dart';
import '../recent/recent_controller.dart';
import '../saved/saved_controller.dart';
import 'image_viewer.dart';
import 'video_viewer.dart';

enum ViewerSource { recent, saved }

class ViewerPage extends StatelessWidget {
  const ViewerPage({
    super.key,
    required this.item,
    required this.source,
  });

  final StatusItem item;
  final ViewerSource source;

  @override
  Widget build(BuildContext context) {
    final body = item.isVideo
        ? VideoViewer(item: item)
        : ImageViewer(item: item);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.displayName ?? 'Status'),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: _ActionBar(item: item, source: source),
    );
  }
}

class _ActionBar extends StatefulWidget {
  const _ActionBar({required this.item, required this.source});

  final StatusItem item;
  final ViewerSource source;

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final isSaved = widget.source == ViewerSource.saved;
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!isSaved)
              _ActionButton(
                icon: Icons.bookmark_add_outlined,
                label: 'Save',
                onTap: _busy ? null : _save,
              ),
            _ActionButton(
              icon: Icons.download_outlined,
              label: 'Gallery',
              onTap: _busy ? null : _saveToGallery,
            ),
            _ActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: _busy ? null : _share,
            ),
            if (isSaved)
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: _busy ? null : _delete,
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _bytes() async {
    final f = widget.item.file;
    if (f != null) return f.readAsBytes();
    // Capture context reference before async gap.
    final recent = context.read<RecentController>();
    final list = await recent.readBytes(widget.item);
    return list is Uint8List ? list : Uint8List.fromList(list);
  }

  Future<File> _materialize() async {
    final existing = widget.item.file;
    if (existing != null) return existing;
    final bytes = await _bytes();
    final tmp = Directory.systemTemp.createTempSync('status_share_');
    final f = File('${tmp.path}/${widget.item.displayName ?? 'status'}');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    // Capture controllers before any async gap.
    final recent = context.read<RecentController>();
    final savedCtrl = context.read<SavedController>();
    try {
      await recent.saveToLibrary(widget.item);
      if (mounted) {
        await savedCtrl.refresh();
        _toast('Saved');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final ok = await Permissions().ensureGallerySave();
      if (!mounted) return;
      if (!ok) {
        _toast('Permission denied');
        return;
      }
      final bytes = await _bytes();
      if (!mounted) return;
      final saved = await MediaSaver().saveBytesToGallery(
        bytes: bytes,
        name: widget.item.displayName ?? 'status',
        kind: widget.item.kind,
      );
      if (mounted) _toast(saved ? 'Added to gallery' : 'Save failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final f = await _materialize();
      await ShareService().share(widget.item, materializedFile: f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    // Capture before async gaps.
    final savedCtrl = context.read<SavedController>();
    final navigator = Navigator.of(context);
    try {
      final store = SavedStore();
      await store.delete(widget.item);
      if (mounted) {
        await savedCtrl.refresh();
        navigator.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap == null ? Colors.white38 : Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? Colors.white38 : Colors.white,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
