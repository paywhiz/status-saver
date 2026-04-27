import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../data/status_item.dart';
import '../recent/recent_controller.dart';

class VideoViewer extends StatefulWidget {
  const VideoViewer({super.key, required this.item});
  final StatusItem item;

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      File file;
      final existing = widget.item.file;
      if (existing != null) {
        file = existing;
      } else {
        // SAF (Android) recent items: copy bytes to a temp file so video_player
        // has a real path to play.
        final recent = context.read<RecentController>();
        final bytes = await recent.readBytes(widget.item);
        final dir = Directory.systemTemp.createTempSync('status_video_');
        file = File(
            '${dir.path}/${widget.item.displayName ?? 'status.mp4'}');
        await file.writeAsBytes(bytes, flush: true);
      }
      final c = VideoPlayerController.file(file);
      await c.initialize();
      await c.setLooping(true);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(
          child: Text('Could not load video',
              style: TextStyle(color: Colors.white)));
    }
    final c = _controller;
    if (c == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: GestureDetector(
          onTap: () =>
              setState(() => c.value.isPlaying ? c.pause() : c.play()),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(c),
              VideoProgressIndicator(c, allowScrubbing: true),
              if (!c.value.isPlaying)
                const Icon(Icons.play_arrow,
                    color: Colors.white70, size: 64),
            ],
          ),
        ),
      ),
    );
  }
}
