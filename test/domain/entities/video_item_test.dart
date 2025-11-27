import 'package:flutter_test/flutter_test.dart';
import 'package:uta_picker/domain/entities/video_item.dart';

void main() {
  group('VideoItem', () {
    test('fromJson creates a valid instance', () {
      final json = {
        'videoId': 'test_id',
        'title': 'Test Video',
        'publishedAt': '2023-01-01',
      };

      final item = VideoItem.fromJson(json);

      expect(item.videoId, 'test_id');
      expect(item.title, 'Test Video');
      expect(item.publishedAt, '2023-01-01');
    });

    test('toJson returns a valid map', () {
      final item = VideoItem(
        videoId: 'test_id',
        title: 'Test Video',
        publishedAt: '2023-01-01',
      );

      final json = item.toJson();

      expect(json['videoId'], 'test_id');
      expect(json['title'], 'Test Video');
      expect(json['publishedAt'], '2023-01-01');
    });
  });
}
