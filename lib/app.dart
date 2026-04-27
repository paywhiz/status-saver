import 'dart:io';

import 'package:flutter/material.dart';

import 'features/recent/recent_page.dart';
import 'features/saved/saved_page.dart';

class StatusSaverApp extends StatelessWidget {
  const StatusSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Status Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF128C7E)),
        useMaterial3: true,
      ),
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
    // iOS has no Recent feed (sandboxing) — show only Saved.
    if (Platform.isIOS) {
      return const SavedPage();
    }
    final pages = const [RecentPage(), SavedPage()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.update), label: 'Recent'),
          NavigationDestination(
              icon: Icon(Icons.bookmark_outline), label: 'Saved'),
        ],
      ),
    );
  }
}
