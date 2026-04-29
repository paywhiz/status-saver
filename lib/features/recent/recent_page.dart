import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/status_item.dart';
import '../../services/video_thumbs.dart';
import '../../widgets/status_tile.dart';
import '../onboarding/onboarding_page.dart';
import '../viewer/viewer_page.dart';
import 'recent_controller.dart';

class RecentPage extends StatefulWidget {
  const RecentPage({super.key});

  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentController>().init();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RecentController>();
    if (!c.ready) {
      return const OnboardingPage();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Images'), Tab(text: 'Videos')],
        ),
        actions: [
          if (!c.hasSecondarySetup)
            IconButton(
              icon: const Icon(Icons.add_business),
              tooltip: 'Add WhatsApp Business',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await context
                    .read<RecentController>()
                    .setupBusiness();
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please pick the WhatsApp Business .Statuses folder',
                      ),
                    ),
                  );
                }
              },
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
                _RecentGrid(items: c.images),
                _RecentGrid(items: c.videos),
              ],
            ),
    );
  }
}

class _RecentGrid extends StatelessWidget {
  const _RecentGrid({required this.items});
  final List<StatusItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No recent statuses.\nOpen WhatsApp, view some statuses, then come back.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final c = context.read<RecentController>();
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: GridView.builder(
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
            thumbnailBytes: () async =>
                it.isVideo ? await VideoThumbs().forItem(it) : await c.readBytes(it),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ViewerPage(
                  items: items,
                  initialIndex: i,
                  source: ViewerSource.recent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
