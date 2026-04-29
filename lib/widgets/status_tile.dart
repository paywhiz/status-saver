import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/status_item.dart';

/// Square thumbnail tile used in both Recent and Saved grids.
class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.item,
    required this.thumbnailBytes,
    required this.onTap,
  });

  final StatusItem item;

  /// For Android SAF items we don't have a File path until we read the bytes,
  /// so the controller passes a small thumbnail buffer in. On Saved items
  /// (real File) the tile can render directly via [Image.file].
  final Future<List<int>?> Function() thumbnailBytes;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final f = item.file;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: Colors.black12,
              child: f != null && item.isImage
                  ? Image.file(f, fit: BoxFit.cover)
                  : _AsyncThumb(loader: thumbnailBytes, isVideo: item.isVideo),
            ),
          ),
          if (item.isVideo)
            const Positioned(
              right: 6,
              bottom: 6,
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white, size: 28),
            ),
        ],
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
