import 'package:flutter_test/flutter_test.dart';

import 'package:status_saver/data/status_item.dart';

void main() {
  group('kindFromName', () {
    test('detects video extensions', () {
      expect(kindFromName('clip.mp4'), StatusKind.video);
      expect(kindFromName('clip.MP4'), StatusKind.video);
      expect(kindFromName('clip.mov'), StatusKind.video);
      expect(kindFromName('clip.3gp'), StatusKind.video);
      expect(kindFromName('clip.webm'), StatusKind.video);
      expect(kindFromName('clip.mkv'), StatusKind.video);
    });

    test('defaults to image for other extensions', () {
      expect(kindFromName('photo.jpg'), StatusKind.image);
      expect(kindFromName('photo.jpeg'), StatusKind.image);
      expect(kindFromName('photo.png'), StatusKind.image);
      expect(kindFromName('photo.gif'), StatusKind.image);
    });
  });
}
