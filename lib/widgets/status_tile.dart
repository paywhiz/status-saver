import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/status_item.dart';

/// Square thumbnail tile used in both Recent and Saved grids.
class StatusTile extends StatefulWidget {
  const StatusTile({
    super.key,
    required this.item,
    required this.thumbnailBytes,
    required this.onTap,
    this.onDownload,
  });

  final StatusItem item;

  /// For Android SAF items we don't have a File path until we read the bytes,
  /// so the controller passes a small thumbnail buffer in. On Saved items
  /// (real File) the tile can render directly via [Image.file].
  final Future<List<int>?> Function() thumbnailBytes;

  final VoidCallback onTap;

  /// Optional per-tile "save to gallery" action. When provided, a small
  /// download icon is rendered in the bottom-right corner.
  final Future<void> Function()? onDownload;

  @override
  State<StatusTile> createState() => _StatusTileState();
}

class _StatusTileState extends State<StatusTile> {
  bool _downloading = false;

  Future<void> _handleDownload() async {
    final cb = widget.onDownload;
    if (cb == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      await cb();
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final f = item.file;
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: Colors.black12,
              child: f != null && item.isImage
                  ? Image.file(f, fit: BoxFit.cover)
                  : _AsyncThumb(
                      loader: widget.thumbnailBytes, isVideo: item.isVideo),
            ),
          ),
          if (item.isVideo)
            const Center(
              child: _PlayBadge(),
            ),
          if (widget.onDownload != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: _DownloadButton(
                busy: _downloading,
                onTap: _handleDownload,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Icon(
        Icons.play_circle_fill,
        color: Colors.white,
        size: 56,
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.download_rounded,
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
  late final Future<List<int>?> _f = widget.loader();

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
        if (bytes == null) {
          return Center(
            child: Icon(
              widget.isVideo ? Icons.movie : Icons.broken_image,
              size: 40,
            ),
          );
        }
        return Image.memory(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          fit: BoxFit.cover,
        );
      },
    );
  }
}
