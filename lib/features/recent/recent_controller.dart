import 'package:flutter/foundation.dart';

import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../../data/status_repository.dart';
import '../settings/settings_controller.dart';

class RecentController extends ChangeNotifier {
  RecentController({
    required StatusRepository repo,
    required SavedStore savedStore,
    SettingsController? settings,
  })  : _repo = repo,
        _saved = savedStore,
        _settings = settings {
    _settings?.addListener(_onSettingsChanged);
  }

  final StatusRepository _repo;
  final SavedStore _saved;
  final SettingsController? _settings;

  List<StatusItem> _items = const [];
  bool _loading = false;
  bool _ready = false;
  bool _hasSecondarySetup = true;

  List<StatusItem> get items => _items;
  bool get loading => _loading;
  bool get ready => _ready;
  bool get hasSecondarySetup => _hasSecondarySetup;

  List<StatusItem> get images =>
      _items.where((i) => i.isImage).toList(growable: false);
  List<StatusItem> get videos =>
      _items.where((i) => i.isVideo).toList(growable: false);

  /// Filtered views by origin — used by separate-mode bottom-nav destinations.
  List<StatusItem> imagesFor(StatusOrigin origin) =>
      _items.where((i) => i.isImage && i.origin == origin).toList(growable: false);
  List<StatusItem> videosFor(StatusOrigin origin) =>
      _items.where((i) => i.isVideo && i.origin == origin).toList(growable: false);

  Future<void> init() async {
    _ready = await _repo.isReady();
    _hasSecondarySetup = await _repo.hasSecondarySetup();
    if (_ready) await refresh();
    notifyListeners();
  }

  Future<bool> setup() async {
    final ok = await _repo.requestSetup();
    _ready = await _repo.isReady();
    _hasSecondarySetup = await _repo.hasSecondarySetup();
    if (_ready) await refresh();
    notifyListeners();
    return ok && _ready;
  }

  Future<bool> setupBusiness() async {
    final ok = await _repo.requestSecondarySetup();
    _hasSecondarySetup = await _repo.hasSecondarySetup();
    if (_hasSecondarySetup) await refresh();
    notifyListeners();
    return ok;
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

  void _onSettingsChanged() {
    // Per-instance enable toggles change which origins listRecent returns.
    // Re-pull when the user flips them from Settings.
    if (_ready) refresh();
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
