import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/status_item.dart';
import '../features/settings/settings_controller.dart';

/// Square thumbnail tile used in both Recent and Saved grids.
class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.item,
    required this.thumbnailBytes,
    required this.onTap,
    this.onSave,
    this.onSaveOverride,
    this.showOriginBadge = false,
  });

  final StatusItem item;

  /// For Android SAF items we don't have a File path until we read the bytes,
  /// so the controller passes a small thumbnail buffer in. On Saved items
  /// (real File) the tile can render directly via [Image.file].
  final Future<List<int>?> Function() thumbnailBytes;

  final VoidCallback onTap;

  /// Tap handler for the per-tile save button. Uses the user's default
  /// destination from Settings.
  final Future<void> Function()? onSave;

  /// Long-press handler — receives the *other* destination so the tile can
  /// offer a one-shot override without opening Settings.
  final Future<void> Function(SaveDestination override)? onSaveOverride;

  /// When true (combined view with both instances enabled), shows a tiny
  /// "P"/"B" chip in the top-left so the user can tell sources apart.
  final bool showOriginBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = item.file;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: f != null && item.isImage
                  ? Image.file(
                      f,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _ThumbFallback(isVideo: false),
                    )
                  : _AsyncThumb(
                      loader: thumbnailBytes, isVideo: item.isVideo),
            ),
          ),
          if (item.isVideo) const Center(child: _PlayBadge()),
          if (showOriginBadge && _originLabel(item.origin) != null)
            Positioned(
              left: 6,
              top: 6,
              child: _OriginChip(label: _originLabel(item.origin)!),
            ),
          if (onSave != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: _SaveButton(
                item: item,
                onSave: onSave!,
                onOverride: onSaveOverride,
              ),
            ),
        ],
      ),
    );
  }
}

String? _originLabel(StatusOrigin origin) {
  switch (origin) {
    case StatusOrigin.whatsapp:
      return 'P';
    case StatusOrigin.whatsappBusiness:
      return 'B';
    case StatusOrigin.imported:
      return null;
  }
}

class _OriginChip extends StatelessWidget {
  const _OriginChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.item,
    required this.onSave,
    required this.onOverride,
  });

  final StatusItem item;
  final Future<void> Function() onSave;
  final Future<void> Function(SaveDestination override)? onOverride;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showOverrideMenu() async {
    final cb = widget.onOverride;
    if (cb == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final destination = await showMenu<SaveDestination>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(
          value: SaveDestination.gallery,
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined),
              SizedBox(width: 12),
              Text('Save to gallery'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SaveDestination.inApp,
          child: Row(
            children: [
              Icon(Icons.bookmark_outline),
              SizedBox(width: 12),
              Text('Save in app'),
            ],
          ),
        ),
      ],
    );
    if (destination != null) {
      await _run(() => cb(destination));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _busy ? null : () => _run(widget.onSave),
      onLongPress: widget.onOverride == null ? null : _showOverrideMenu,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
        ),
        alignment: Alignment.center,
        child: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.save_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }
}

class _AsyncThumb extends StatefulWidget {
  const _AsyncThumb({required this.loader, required this.isVideo});

  final Future<List<int>?> Function() loader;
  final bool isVideo;

  @override
  State<_AsyncThumb> createState() => _AsyncThumbState();
}

class _AsyncThumbState extends State<_AsyncThumb> {
  late Future<List<int>?> _f;

  @override
  void initState() {
    super.initState();
    _f = widget.loader();
  }

  @override
  void didUpdateWidget(covariant _AsyncThumb old) {
    super.didUpdateWidget(old);
    // GridView recycles tile state across items. Without this the future from
    // a previous item would stay attached and the new tile would either keep
    // a stale spinner or render the wrong thumbnail.
    if (!identical(old.loader, widget.loader)) {
      _f = widget.loader();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>?>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return _ThumbFallback(isVideo: widget.isVideo);
        }
        return Image.memory(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _ThumbFallback(isVideo: widget.isVideo),
        );
      },
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback({required this.isVideo});
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        isVideo ? Icons.movie : Icons.broken_image,
        size: 40,
      ),
    );
  }
}
