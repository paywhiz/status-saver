import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/status_item.dart';
import '../../services/image_bytes_cache.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, required this.item, this.onZoomChanged});
  final StatusItem item;

  /// Called whenever this image enters or exits a zoomed state. The viewer
  /// page disables PageView swipes while any image is zoomed so a two-finger
  /// pinch isn't stolen by horizontal page advancement.
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  static const double _zoomEpsilon = 1.01;

  Uint8List? _bytes;
  Object? _error;
  final TransformationController _controller = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChange);
    _load();
  }

  @override
  void didUpdateWidget(covariant ImageViewer old) {
    super.didUpdateWidget(old);
    // PageView may reuse this State across items if a key is missing.
    // Reset transform defensively so a previously-zoomed image doesn't
    // bleed into the next one and steal the gesture arena.
    if (old.item.id != widget.item.id) {
      _resetZoom();
      _bytes = null;
      _error = null;
      _load();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTransformChange() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = scale > _zoomEpsilon;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  Future<void> _load() async {
    try {
      final b = await ImageBytesCache().forItemFull(widget.item);
      if (mounted) {
        setState(() => _bytes = b);
        // Reset transform after the image becomes visible — InteractiveViewer
        // wires its gesture recognizers when the child is first laid out, and
        // ensuring identity here guarantees pinch works on the new page.
        _resetZoom();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(
          child: Text('Could not load image',
              style: TextStyle(color: Colors.white)));
    }
    if (_bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      // Double-tap is the universal escape hatch out of any partially-zoomed
      // state — guarantees the user can't get stuck.
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.memory(
            _bytes!,
            errorBuilder: (_, __, ___) => const Text(
              'Could not load image',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
