import 'package:flutter/foundation.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../../data/status_repository.dart';

class RecentController extends ChangeNotifier {
  RecentController({
    required StatusRepository repo,
    required SavedStore savedStore,
  })  : _repo = repo,
        _saved = savedStore;

  final StatusRepository _repo;
  final SavedStore _saved;

  List<StatusItem> _items = const [];
  bool _loading = false;
  bool _ready = false;

  List<StatusItem> get items => _items;
  bool get loading => _loading;
  bool get ready => _ready;

  List<StatusItem> get images =>
      _items.where((i) => i.isImage).toList(growable: false);
  List<StatusItem> get videos =>
      _items.where((i) => i.isVideo).toList(growable: false);

  Future<void> init() async {
    _ready = await _repo.isReady();
    if (_ready) await refresh();
    notifyListeners();
  }

  Future<bool> setup() async {
    final ok = await _repo.requestSetup();
    _ready = await _repo.isReady();
    if (_ready) await refresh();
    notifyListeners();
    return ok && _ready;
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.listRecent();
    _loading = false;
    notifyListeners();
  }

  Future<List<int>> readBytes(StatusItem item) => _repo.readBytes(item);

  /// Copies a recent item into the SavedStore, returning the saved version.
  Future<StatusItem> saveToLibrary(StatusItem item) async {
    final bytes = await _repo.readBytes(item);
    final name =
        item.displayName ?? 'status_${DateTime.now().millisecondsSinceEpoch}';
    return _saved.saveBytes(name: name, bytes: bytes);
  }
}
