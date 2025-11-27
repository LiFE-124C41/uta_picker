import 'package:flutter_test/flutter_test.dart';
import 'package:uta_picker/domain/entities/playlist_item.dart';

void main() {
  group('PlaylistItem', () {
    test('fromJson creates a valid instance', () {
      final json = {
        'video_id': 'test_id',
        'start_sec': 10,
        'end_sec': 20,
        'video_title': 'Test Video',
        'song_title': 'Test Song',
      };

      final item = PlaylistItem.fromJson(json);

      expect(item.videoId, 'test_id');
      expect(item.startSec, 10);
      expect(item.endSec, 20);
      expect(item.videoTitle, 'Test Video');
      expect(item.songTitle, 'Test Song');
    });

    test('fromJson handles backward compatibility for songTitle', () {
      final json = {
        'video_id': 'test_id',
        'title': 'Old Title',
      };

      final item = PlaylistItem.fromJson(json);

      expect(item.videoId, 'test_id');
      expect(item.songTitle, 'Old Title');
    });

    test('toJson returns a valid map', () {
      final item = PlaylistItem(
        videoId: 'test_id',
        startSec: 10,
        endSec: 20,
        videoTitle: 'Test Video',
        songTitle: 'Test Song',
      );

      final json = item.toJson();

      expect(json['video_id'], 'test_id');
      expect(json['start_sec'], 10);
      expect(json['end_sec'], 20);
      expect(json['video_title'], 'Test Video');
      expect(json['song_title'], 'Test Song');
    });
  });
}
