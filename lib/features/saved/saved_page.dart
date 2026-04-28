import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../../widgets/status_tile.dart';
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
            onPressed: c.loading ? null : c.refresh,
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
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );
    if (result == null || result.files.isEmpty) return;
    final store = SavedStore();
    for (final f in result.files) {
      final p = f.path;
      if (p == null) continue;
      await store.saveFile(source: File(p));
    }
    if (mounted) await context.read<SavedController>().refresh();
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.source});

  final List<StatusItem> items;
  final ViewerSource source;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing saved yet.\nView a status, then tap Save.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return StatusTile(
          item: it,
          thumbnailBytes: () async => it.file?.readAsBytes(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ViewerPage(item: it, source: source),
            ),
          ),
        );
      },
    );
  }
}
