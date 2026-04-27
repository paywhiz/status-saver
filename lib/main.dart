import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/android_status_source.dart';
import 'data/ios_status_source.dart';
import 'data/saved_store.dart';
import 'data/status_repository.dart';
import 'features/recent/recent_controller.dart';
import 'features/saved/saved_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final SavedStore _saved = SavedStore();
  late final StatusRepository _repo =
      Platform.isAndroid ? AndroidStatusSource() : NullStatusRepository();
  IosShareIngest? _iosIngest;

  late final SavedController _savedController = SavedController(_saved);
  late final RecentController _recentController = RecentController(
    repo: _repo,
    savedStore: _saved,
  );

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _iosIngest = IosShareIngest(_saved);
      _iosIngest!.attach().then((_) => _savedController.refresh());
    }
  }

  @override
  void dispose() {
    _iosIngest?.dispose();
    _savedController.dispose();
    _recentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _savedController),
        ChangeNotifierProvider.value(value: _recentController),
      ],
      child: const StatusSaverApp(),
    );
  }
}
