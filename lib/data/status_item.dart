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

StatusKind kindFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.3gp') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.webm')) {
    return StatusKind.video;
  }
  return StatusKind.image;
}
