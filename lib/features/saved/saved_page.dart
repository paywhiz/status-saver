import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../../services/download_action.dart';
import '../../services/video_thumbs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_tile.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_page.dart';
import '../viewer/viewer_page.dart';
import 'saved_controller.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedController>().refresh();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SavedController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Images'), Tab(text: 'Videos')],
        ),
        actions: [
          if (Platform.isIOS)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Import from Files',
              onPressed: _importFromFiles,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: c.loading ? null : c.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _Grid(items: c.images, source: ViewerSource.saved),
                _Grid(items: c.videos, source: ViewerSource.saved),
              ],
            ),
    );
  }

  Future<void> _importFromFiles() async {
    final store = context.read<SavedStore>();
    final controller = context.read<SavedController>();
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );
    if (result == null || result.files.isEmpty) return;
    for (final f in result.files) {
      final p = f.path;
      if (p == null) continue;
      await store.saveFile(source: File(p));
    }
    if (mounted) await controller.refresh();
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.source});

  final List<StatusItem> items;
  final ViewerSource source;

  @override
  Widget build(BuildContext context) {
    final c = context.read<SavedController>();
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: c.refresh,
        child: ListView(
          children: const [
            SizedBox(
              height: 480,
              child: EmptyState(
                icon: Icons.bookmark_outline,
                title: 'Nothing saved yet',
                body: 'View a status, tap Save, and it\'ll appear here.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, i) {
          final it = items[i];
          return StatusTile(
            item: it,
            thumbnailBytes: () async => it.isVideo
                ? await VideoThumbs().forItem(it)
                : await it.file?.readAsBytes(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ViewerPage(
                  items: items,
                  initialIndex: i,
                  source: source,
                ),
              ),
            ),
            // From the Saved tab "save" implicitly means "to gallery" — the
            // item is already in the in-app store.
            onSave: () => saveStatusItem(context, it,
                override: SaveDestination.gallery),
          );
        },
      ),
    );
  }
}
