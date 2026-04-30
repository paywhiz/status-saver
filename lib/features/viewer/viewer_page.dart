import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../../services/download_action.dart';
import '../../services/share_service.dart';
import '../recent/recent_controller.dart';
import '../saved/saved_controller.dart';
import '../settings/settings_controller.dart';
import 'image_viewer.dart';
import 'video_viewer.dart';

enum ViewerSource { recent, saved }

class ViewerPage extends StatefulWidget {
  const ViewerPage({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.source,
  });

  final List<StatusItem> items;
  final int initialIndex;
  final ViewerSource source;

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final PageController _pc;
  late List<StatusItem> _items;
  late int _index;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    _index = widget.initialIndex.clamp(0, _items.length - 1);
    _pc = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _goPrev() => _pc.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  void _goNext() => _pc.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  /// Removes the current item from the list (after a Delete action).
  /// Pops the page if the list becomes empty.
  void _removeCurrent() {
    if (_items.length <= 1) {
      Navigator.of(context).pop();
      return;
    }
    final wasLast = _index == _items.length - 1;
    setState(() {
      _items.removeAt(_index);
      if (wasLast) _index = _items.length - 1;
    });
    if (wasLast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pc.hasClients) _pc.jumpToPage(_index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pc,
          itemCount: _items.length,
          // While the active image is zoomed, swallow horizontal swipes so a
          // two-finger pinch isn't stolen by the PageView gesture arena.
          physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final it = _items[i];
            if (it.isVideo) {
              return VideoViewer(
                key: ValueKey(it.id),
                item: it,
                onPrev: i > 0 ? _goPrev : null,
                onNext: i < _items.length - 1 ? _goNext : null,
              );
            }
            return ImageViewer(
              key: ValueKey(it.id),
              item: it,
              onZoomChanged: (z) {
                if (z != _zoomed) setState(() => _zoomed = z);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _ActionBar(
        item: current,
        source: widget.source,
        onDeleted: _removeCurrent,
      ),
    );
  }
}

class _ActionBar extends StatefulWidget {
  const _ActionBar({
    required this.item,
    required this.source,
    required this.onDeleted,
  });

  final StatusItem item;
  final ViewerSource source;
  final VoidCallback onDeleted;

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final isSaved = widget.source == ViewerSource.saved;
    final destination = context.watch<SettingsController>().saveDestination;
    final saveLabel = isSaved
        ? 'Gallery'
        : (destination == SaveDestination.gallery ? 'Gallery' : 'Save');
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.save_alt_rounded,
              label: saveLabel,
              onTap: _busy ? null : _save,
              onLongPress:
                  _busy || isSaved ? null : _showSaveDestinationMenu,
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

  Future<void> _showSaveDestinationMenu() async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final destination = await showMenu<SaveDestination>(
      context: context,
      position: RelativeRect.fromLTRB(
        20, overlay.size.height - 240, 20, 80,
      ),
      items: const [
        PopupMenuItem(
          value: SaveDestination.gallery,
          child: Row(children: [
            Icon(Icons.photo_library_outlined),
            SizedBox(width: 12),
            Text('Save to gallery'),
          ]),
        ),
        PopupMenuItem(
          value: SaveDestination.inApp,
          child: Row(children: [
            Icon(Icons.bookmark_outline),
            SizedBox(width: 12),
            Text('Save in app'),
          ]),
        ),
      ],
    );
    if (destination != null && mounted) {
      setState(() => _busy = true);
      try {
        await saveStatusItem(context, widget.item, override: destination);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
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
    try {
      // From the Saved tab the only sensible "save" is "to gallery"; the item
      // is already in the in-app store.
      final override = widget.source == ViewerSource.saved
          ? SaveDestination.gallery
          : null;
      await saveStatusItem(context, widget.item, override: override);
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
    final savedCtrl = context.read<SavedController>();
    final store = context.read<SavedStore>();
    try {
      await store.delete(widget.item);
      if (!mounted) return;
      await savedCtrl.refresh();
      if (!mounted) return;
      widget.onDeleted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
