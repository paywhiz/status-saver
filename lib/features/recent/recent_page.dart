import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/status_item.dart';
import '../../services/download_action.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_tile.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_page.dart';
import '../viewer/viewer_page.dart';
import 'recent_controller.dart';

/// Recent statuses page.
///
/// Reused for three navigation roles:
///   * Combined view (no [originFilter])
///   * Personal-only destination ([originFilter] = whatsapp)
///   * Business-only destination ([originFilter] = whatsappBusiness)
class RecentPage extends StatefulWidget {
  const RecentPage({super.key, this.originFilter, this.title});

  final StatusOrigin? originFilter;
  final String? title;

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
    final settings = context.watch<SettingsController>();
    final filter = widget.originFilter;
    final images = filter == null ? c.images : c.imagesFor(filter);
    final videos = filter == null ? c.videos : c.videosFor(filter);
    // Only show the per-tile origin badge in combined view when both
    // instances are enabled — otherwise it's noise.
    final showOriginBadge =
        filter == null && settings.bothInstancesEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Recent'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Images'), Tab(text: 'Videos')],
        ),
        actions: [
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
                _RecentGrid(items: images, showOriginBadge: showOriginBadge),
                _RecentGrid(items: videos, showOriginBadge: showOriginBadge),
              ],
            ),
    );
  }
}

class _RecentGrid extends StatelessWidget {
  const _RecentGrid({required this.items, required this.showOriginBadge});
  final List<StatusItem> items;
  final bool showOriginBadge;

  @override
  Widget build(BuildContext context) {
    final c = context.read<RecentController>();
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: c.refresh,
        child: ListView(
          children: const [
            SizedBox(
              height: 480,
              child: EmptyState(
                icon: Icons.update,
                title: 'No statuses yet',
                body: 'Open WhatsApp, view a few statuses, then pull to refresh.',
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
        // Default cacheExtent (~250 px) is too tight for a 3-column 140-px
        // grid: tiles a single screen away get torn down and have to re-decode
        // when the user scrolls back. 1200 keeps roughly the next two screens
        // worth of tiles built so they stay warm.
        cacheExtent: 1200,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, i) {
          final it = items[i];
          return StatusTile(
            key: ValueKey(it.uri ?? it.file?.path ?? it.id),
            item: it,
            showOriginBadge: showOriginBadge,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ViewerPage(
                  items: items,
                  initialIndex: i,
                  source: ViewerSource.recent,
                ),
              ),
            ),
            onSave: () => saveStatusItem(context, it),
            onSaveOverride: (override) =>
                saveStatusItem(context, it, override: override),
          );
        },
      ),
    );
  }
}
