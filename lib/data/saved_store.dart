import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'status_item.dart';

/// App-private store of saved statuses. Lives in
/// `<appDocs>/saved/` and is the single source of truth for the Saved tab.
class SavedStore {
  Directory? _root;

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/saved');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _root = dir;
    return dir;
  }

  Future<List<StatusItem>> list() async {
    final dir = await _dir();
    final entries = await dir.list().toList();
    final files = entries.whereType<File>().toList();
    files.sort((a, b) =>
        b.statSync().modified.compareTo(a.statSync().modified));
    return files.map(_toItem).toList();
  }

  StatusItem _toItem(File f) {
    final name = f.uri.pathSegments.last;
    return StatusItem(
      id: f.path,
      kind: kindFromName(name),
      origin: StatusOrigin.imported,
      modified: f.statSync().modified,
      file: f,
      displayName: name,
    );
  }

  /// Copies [bytes] (or [sourceFile]) into the saved/ dir under [name],
  /// returning the resulting [StatusItem].
  Future<StatusItem> saveBytes({
    required String name,
    required List<int> bytes,
  }) async {
    final dir = await _dir();
    final dest = File('${dir.path}/${_uniqueName(dir, name)}');
    await dest.writeAsBytes(bytes, flush: true);
    return _toItem(dest);
  }

  Future<StatusItem> saveFile({
    required File source,
    String? overrideName,
  }) async {
    final dir = await _dir();
    final name = overrideName ?? source.uri.pathSegments.last;
    final dest = File('${dir.path}/${_uniqueName(dir, name)}');
    await source.copy(dest.path);
    return _toItem(dest);
  }

  Future<bool> delete(StatusItem item) async {
    final f = item.file;
    if (f == null || !await f.exists()) return false;
    await f.delete();
    return true;
  }

  String _uniqueName(Directory dir, String name) {
    var candidate = name;
    var n = 1;
    while (File('${dir.path}/$candidate').existsSync()) {
      final dot = name.lastIndexOf('.');
      final stem = dot == -1 ? name : name.substring(0, dot);
      final ext = dot == -1 ? '' : name.substring(dot);
      candidate = '${stem}_$n$ext';
      n++;
    }
    return candidate;
  }
}
