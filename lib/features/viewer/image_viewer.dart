import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/status_item.dart';
import '../recent/recent_controller.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, required this.item});
  final StatusItem item;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  Uint8List? _bytes;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
    return InteractiveViewer(
      child: Center(child: Image.memory(_bytes!)),
    );
  }
}
