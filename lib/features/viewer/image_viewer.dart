import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/status_item.dart';
import '../recent/recent_controller.dart';

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
      final f = widget.item.file;
      if (f != null) {
        final b = await f.readAsBytes();
        if (mounted) setState(() => _bytes = b);
        return;
      }
      final recent = context.read<RecentController>();
      final raw = await recent.readBytes(widget.item);
      final b = raw is Uint8List ? raw : Uint8List.fromList(raw);
      if (mounted) setState(() => _bytes = b);
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
