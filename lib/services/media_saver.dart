import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';

import '../data/status_item.dart';

class MediaSaver {
  /// Folder/album name where saves are organized. On Android the OS routes
  /// images into `Pictures/<album>/` and videos into `Movies/<album>/`; on
  /// iOS this becomes a Photos album of the same name containing both.
  static const String albumName = 'Status Saver';

  /// Persists [bytes] to the device gallery (Photos on iOS, Pictures/Movies
  /// via MediaStore on Android), under the [albumName] folder. Returns true
  /// on success.
  Future<bool> saveBytesToGallery({
    required Uint8List bytes,
    required String name,
    required StatusKind kind,
  }) async {
    try {
      if (kind == StatusKind.video) {
        final tmp = await _writeTemp(bytes, name);
        await Gal.putVideo(tmp, album: albumName);
      } else {
        await Gal.putImageBytes(bytes, album: albumName, name: _stripExt(name));
      }
      return true;
    } on GalException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  String _stripExt(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }

  Future<String> _writeTemp(Uint8List bytes, String name) async {
    final dir = Directory.systemTemp.createTempSync('status_saver_');
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }
}
