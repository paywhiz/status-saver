import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../data/status_item.dart';

class ShareService {
  Future<void> share(StatusItem item, {File? materializedFile}) async {
    final f = materializedFile ?? item.file;
    if (f == null) {
      throw ArgumentError('share() needs a real File on disk');
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
  }
}
