import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/status_item.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/recent/recent_page.dart';
import 'features/saved/saved_page.dart';
import 'features/settings/settings_controller.dart';
import 'theme.dart';

class StatusSaverApp extends StatelessWidget {
  const StatusSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp(
      title: 'Status Saver',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.themeMode,
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // iOS has no Recent feed (sandboxing) — show only Saved.
    if (Platform.isIOS) {
      return const SavedPage();
    }

    // Onboarding gates the entire app on first launch.
    if (!settings.onboardingCompleted) {
      return const OnboardingPage();
    }

    final destinations = _destinations(settings);
    final pages = destinations.map((d) => d.page).toList();
    final clamped = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: clamped, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: clamped,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }

  /// Bottom-nav layout depends on which WhatsApp instances are enabled and
  /// whether the user picked Combined vs Separate view mode.
  List<_Destination> _destinations(SettingsController s) {
    if (s.bothInstancesEnabled && s.viewMode == RecentViewMode.separate) {
      return const [
        _Destination(
          icon: Icons.chat_outlined,
          label: 'Personal',
          page: RecentPage(
            originFilter: StatusOrigin.whatsapp,
            title: 'Personal',
          ),
        ),
        _Destination(
          icon: Icons.storefront_outlined,
          label: 'Business',
          page: RecentPage(
            originFilter: StatusOrigin.whatsappBusiness,
            title: 'Business',
          ),
        ),
        _Destination(
          icon: Icons.bookmark_outline,
          label: 'Saved',
          page: SavedPage(),
        ),
      ];
    }
    return const [
      _Destination(
        icon: Icons.update,
        label: 'Recent',
        page: RecentPage(),
      ),
      _Destination(
        icon: Icons.bookmark_outline,
        label: 'Saved',
        page: SavedPage(),
      ),
    ];
  }
}

class _Destination {
  const _Destination({required this.icon, required this.label, required this.page});
  final IconData icon;
  final String label;
  final Widget page;
}
