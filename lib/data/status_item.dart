import 'dart:io';

enum StatusKind { image, video }

enum StatusOrigin { whatsapp, whatsappBusiness, imported }

/// A single status item.
///
/// On Android, a "recent" item is backed by a SAF document URI (no [file]).
/// Once saved or imported, it lives at a real [file] path inside the app's
/// private saved/ dir.
class StatusItem {
  StatusItem({
    required this.id,
    required this.kind,
    required this.origin,
    required this.modified,
    this.file,
    this.uri,
    this.displayName,
  }) : assert(file != null || uri != null,
            'StatusItem needs either a file or a SAF uri');

  final String id;
  final StatusKind kind;
  final StatusOrigin origin;
  final DateTime modified;
  final File? file;
  final String? uri;
  final String? displayName;

  bool get isVideo => kind == StatusKind.video;
  bool get isImage => kind == StatusKind.image;
}

const Set<String> imageExtensions = {
  '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.bmp',
};

const Set<String> videoExtensions = {
  '.mp4', '.mov', '.3gp', '.mkv', '.webm',
};

bool _hasExtension(String lowerName, Set<String> extensions) {
  for (final ext in extensions) {
    if (lowerName.endsWith(ext)) return true;
  }
  return false;
}

bool isMediaFileName(String name) {
  final lower = name.toLowerCase();
  return _hasExtension(lower, imageExtensions) ||
      _hasExtension(lower, videoExtensions);
}

StatusKind kindFromName(String name) {
  final lower = name.toLowerCase();
  if (_hasExtension(lower, videoExtensions)) {
    return StatusKind.video;
  }
  return StatusKind.image;
}
