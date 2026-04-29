import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../data/status_item.dart';
import '../recent/recent_controller.dart';

class VideoViewer extends StatefulWidget {
  const VideoViewer({
    super.key,
    required this.item,
    this.onPrev,
    this.onNext,
  });

  final StatusItem item;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _showControls = true;
  Timer? _hideTimer;
  int _lastTickSec = -1;

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
      c.addListener(_onTick);
      setState(() => _controller = c);
      _scheduleHide();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    final sec = c.value.position.inSeconds;
    if (sec != _lastTickSec) {
      _lastTickSec = sec;
      setState(() {});
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onTick);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: AnimatedOpacity(
            opacity: _showControls ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: _Controls(
                controller: c,
                onPrev: widget.onPrev,
                onNext: widget.onNext,
                onTogglePlay: _togglePlay,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.onPrev,
    required this.onNext,
    required this.onTogglePlay,
  });

  final VideoPlayerController controller;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final isPlaying = controller.value.isPlaying;
    return Container(
      color: Colors.black26,
      child: Stack(
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  color: Colors.white,
                  disabledColor: Colors.white24,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: onPrev,
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 72,
                  color: Colors.white,
                  icon: Icon(isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  onPressed: onTogglePlay,
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 48,
                  color: Colors.white,
                  disabledColor: Colors.white24,
                  icon: const Icon(Icons.skip_next),
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _fmt(controller.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(controller.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }
}
