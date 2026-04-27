import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'status_item.dart';
import 'status_repository.dart';

const _prefKeyMessenger = 'saf.uri.whatsapp';
const _prefKeyBusiness = 'saf.uri.whatsapp_business';

/// Reads WhatsApp / WhatsApp Business `.Statuses` directories on Android via
/// the Storage Access Framework. The user grants directory access once;
/// the URI is persisted across launches.
class AndroidStatusSource implements StatusRepository {
  AndroidStatusSource({SafUtil? saf}) : _saf = saf ?? SafUtil();

  final SafUtil _saf;

  @override
  Future<bool> isReady() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString(_prefKeyMessenger);
    final b = prefs.getString(_prefKeyBusiness);
    return (m != null) || (b != null);
  }

  @override
  Future<bool> requestSetup() async {
    final granted = await pickMessengerFolder();
    // Business folder is optional — many users don't have WhatsApp Business.
    await pickBusinessFolder();
    return granted || (await prefs).getString(_prefKeyBusiness) != null;
  }

  Future<SharedPreferences> get prefs async =>
      SharedPreferences.getInstance();

  Future<bool> pickMessengerFolder() => _pick(_prefKeyMessenger);
  Future<bool> pickBusinessFolder() => _pick(_prefKeyBusiness);

  Future<bool> _pick(String key) async {
    final result = await _saf.pickDirectory(persistablePermission: true);
    if (result == null) return false;
    final p = await prefs;
    await p.setString(key, result.uri);
    return true;
  }

  Future<String?> messengerUri() async =>
      (await prefs).getString(_prefKeyMessenger);
  Future<String?> businessUri() async =>
      (await prefs).getString(_prefKeyBusiness);

  Future<void> clear() async {
    final p = await prefs;
    await p.remove(_prefKeyMessenger);
    await p.remove(_prefKeyBusiness);
  }

  @override
  Future<List<StatusItem>> listRecent() async {
    final out = <StatusItem>[];
    final m = await messengerUri();
    final b = await businessUri();

    if (m != null) {
      out.addAll(await _list(m, StatusOrigin.whatsapp));
    }
    if (b != null) {
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
    final bytes = await _saf.readFileBytes(uri);
    if (bytes == null) {
      throw StateError('SAF read returned null for $uri');
    }
    return bytes;
  }
}
