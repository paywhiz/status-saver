import 'package:flutter/foundation.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';

class SavedController extends ChangeNotifier {
  SavedController(this._store);

  final SavedStore _store;

  List<StatusItem> _items = const [];
  bool _loading = false;

  List<StatusItem> get items => _items;
  bool get loading => _loading;

  List<StatusItem> get images =>
      _items.where((i) => i.isImage).toList(growable: false);
  List<StatusItem> get videos =>
      _items.where((i) => i.isVideo).toList(growable: false);

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    _items = await _store.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> remove(StatusItem item) async {
    await _store.delete(item);
    await refresh();
  }
}
