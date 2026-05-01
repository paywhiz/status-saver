import 'package:flutter/foundation.dart';

import '../../data/gallery_album_source.dart';
import '../../data/saved_store.dart';
import '../../data/status_item.dart';
import '../settings/settings_controller.dart';

class SavedController extends ChangeNotifier {
  SavedController(
    this._store, {
    GalleryAlbumSource? gallery,
    SettingsController? settings,
  })  : _gallery = gallery,
        _settings = settings {
    _lastDestination = _settings?.saveDestination;
    _settings?.addListener(_onSettingsChanged);
  }

  final SavedStore _store;
  final GalleryAlbumSource? _gallery;
  final SettingsController? _settings;
  SaveDestination? _lastDestination;

  List<StatusItem> _items = const [];
  bool _loading = false;

  List<StatusItem> get items => _items;
  bool get loading => _loading;

  List<StatusItem> get images =>
      _items.where((i) => i.isImage).toList(growable: false);
  List<StatusItem> get videos =>
      _items.where((i) => i.isVideo).toList(growable: false);

  /// True when the Saved tab is reflecting the device gallery album rather
  /// than the in-app store. Drives empty-state copy and routes [remove]
  /// through the native MediaStore delete instead of the in-app store.
  bool get sourceIsGallery =>
      _gallery != null &&
      _settings?.saveDestination == SaveDestination.gallery;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    if (sourceIsGallery) {
      _items = await _gallery!.list();
    } else {
      _items = await _store.list();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> remove(StatusItem item) async {
    if (sourceIsGallery) {
      // Native delete shows a system confirmation on Android 11+; only refresh
      // when the user confirmed (the platform returned true).
      final ok = await _gallery!.delete(item);
      if (ok) await refresh();
      return;
    }
    await _store.delete(item);
    await refresh();
  }

  void _onSettingsChanged() {
    // Only re-pull when the destination flips, since other settings (theme,
    // view mode, instance toggles) don't affect what the Saved tab shows.
    final current = _settings?.saveDestination;
    if (current != _lastDestination) {
      _lastDestination = current;
      refresh();
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
