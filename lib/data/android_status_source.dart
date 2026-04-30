import 'package:flutter/services.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/settings_controller.dart';
import 'status_item.dart';
import 'status_repository.dart';

const _prefKeyMessenger = 'saf.uri.whatsapp';
const _prefKeyBusiness = 'saf.uri.whatsapp_business';

// `EXTRA_INITIAL_URI` is honored by DocumentsUI when expressed as a `document/`
// URI; the older `tree/` form is silently ignored on most ROMs and the picker
// falls back to its last-used location.
const _waStatusesInitialUri =
    'content://com.android.externalstorage.documents/document/'
    'primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses';

const _wabStatusesInitialUri =
    'content://com.android.externalstorage.documents/document/'
    'primary%3AAndroid%2Fmedia%2Fcom.whatsapp.w4b%2FWhatsApp%20Business%2FMedia%2F.Statuses';

/// Reads WhatsApp / WhatsApp Business `.Statuses` directories on Android via
/// the Storage Access Framework. The user grants directory access once;
/// the URI is persisted across launches.
///
/// The optional [SettingsController] lets users disable an instance from
/// Settings without losing the persisted SAF permission — `listRecent` skips
/// disabled origins while keeping the URI cached for re-enable.
class AndroidStatusSource implements StatusRepository {
  AndroidStatusSource({SafUtil? saf, SettingsController? settings})
      : _saf = saf ?? SafUtil(),
        _settings = settings;

  final SafUtil _saf;
  final SettingsController? _settings;

  static const _channel = MethodChannel('com.example.status_saver/saf');

  @override
  Future<bool> isReady() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString(_prefKeyMessenger);
    final b = prefs.getString(_prefKeyBusiness);
    return (m != null) || (b != null);
  }

  @override
  Future<bool> requestSetup() => pickMessengerFolder();

  @override
  Future<bool> hasSecondarySetup() async =>
      (await prefs).getString(_prefKeyBusiness) != null;

  @override
  Future<bool> requestSecondarySetup() => pickBusinessFolder();

  Future<SharedPreferences> get prefs async =>
      SharedPreferences.getInstance();

  Future<bool> pickMessengerFolder() => _pick(
        _prefKeyMessenger,
        _waStatusesInitialUri,
        mustContain: 'com.whatsapp/',
        mustNotContain: 'com.whatsapp.w4b',
      );

  Future<bool> pickBusinessFolder() => _pick(
        _prefKeyBusiness,
        _wabStatusesInitialUri,
        mustContain: 'com.whatsapp.w4b',
      );

  Future<bool> _pick(
    String key,
    String initialUri, {
    required String mustContain,
    String? mustNotContain,
  }) async {
    final result = await _saf.pickDirectory(
      persistablePermission: true,
      initialUri: initialUri,
    );
    if (result == null) return false;
    final decoded = Uri.decodeFull(result.uri);
    if (!decoded.contains(mustContain)) return false;
    if (mustNotContain != null && decoded.contains(mustNotContain)) return false;
    final p = await prefs;
    await p.setString(key, result.uri);
    return true;
  }

  Future<String?> messengerUri() async =>
      (await prefs).getString(_prefKeyMessenger);
  Future<String?> businessUri() async =>
      (await prefs).getString(_prefKeyBusiness);

  Future<void> clearMessenger() async =>
      (await prefs).remove(_prefKeyMessenger);
  Future<void> clearBusiness() async =>
      (await prefs).remove(_prefKeyBusiness);

  Future<void> clear() async {
    await clearMessenger();
    await clearBusiness();
  }

  @override
  Future<List<StatusItem>> listRecent() async {
    final out = <StatusItem>[];
    final m = await messengerUri();
    final b = await businessUri();

    final personalOn = _settings?.personalEnabled ?? true;
    final businessOn = _settings?.businessEnabled ?? true;

    if (m != null && personalOn) {
      out.addAll(await _list(m, StatusOrigin.whatsapp));
    }
    if (b != null && businessOn) {
      out.addAll(await _list(b, StatusOrigin.whatsappBusiness));
    }

    out.sort((a, b) => b.modified.compareTo(a.modified));
    return out;
  }

  Future<List<StatusItem>> _list(String dirUri, StatusOrigin origin) async {
    final List<SafDocumentFile> children;
    try {
      children = await _saf.list(dirUri);
    } catch (_) {
      return const [];
    }
    return [
      for (final c in children)
        if (!c.isDir && !c.name.startsWith('.') && c.name != '.nomedia')
          StatusItem(
            id: c.uri,
            kind: kindFromName(c.name),
            origin: origin,
            modified: DateTime.fromMillisecondsSinceEpoch(c.lastModified),
            uri: c.uri,
            displayName: c.name,
          ),
    ];
  }

  @override
  Future<List<int>> readBytes(StatusItem item) async {
    final uri = item.uri;
    if (uri == null) {
      final f = item.file;
      if (f != null) return f.readAsBytes();
      throw StateError('Item has neither uri nor file');
    }
    final bytes = await _channel.invokeMethod<Uint8List>('readBytes', {'uri': uri});
    return bytes ?? (throw StateError('readBytes returned null for $uri'));
  }
}
