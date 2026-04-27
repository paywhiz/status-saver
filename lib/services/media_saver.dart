import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../data/status_item.dart';

class MediaSaver {
  /// Persists [bytes] to the device gallery (Photos on iOS, Pictures/Movies
  /// via MediaStore on Android). Returns true on success.
  Future<bool> saveBytesToGallery({
    required Uint8List bytes,
    required String name,
    required StatusKind kind,
  }) async {
    final dynamic result = kind == StatusKind.video
        ? await ImageGallerySaverPlus.saveFile(
            await _writeTemp(bytes, name),
            name: name,
          )
        : await ImageGallerySaverPlus.saveImage(
            bytes,
            name: _stripExt(name),
            quality: 100,
          );
    if (result is Map) {
      return result['isSuccess'] == true;
    }
    return result != null;
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
