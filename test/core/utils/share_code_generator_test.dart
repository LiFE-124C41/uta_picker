import 'package:flutter_test/flutter_test.dart';
import 'package:uta_picker/core/utils/share_code_generator.dart';

void main() {
  group('ShareCodeGenerator', () {
    const videoId = 'dQw4w9WgXcQ';

    test('should encode and decode correctly with all fields', () {
      const start = 120;
      const end = 180;
      const title = 'Test Title';

      final code = ShareCodeGenerator.encode(
        videoId: videoId,
        startSec: start,
        endSec: end,
        title: title,
      );

      final decoded = ShareCodeGenerator.decode(code);

      expect(decoded['videoId'], videoId);
      expect(decoded['startSec'], start);
      expect(decoded['endSec'], end);
      expect(decoded['title'], title);
    });

    test('should encode and decode correctly with Japanese title', () {
      const title = '日本語のタイトル';
      final code = ShareCodeGenerator.encode(
        videoId: videoId,
        title: title,
      );

      final decoded = ShareCodeGenerator.decode(code);
      expect(decoded['videoId'], videoId);
      expect(decoded['title'], title);
    });

    test('should handle null start/end times', () {
      final code = ShareCodeGenerator.encode(videoId: videoId);
      final decoded = ShareCodeGenerator.decode(code);

      expect(decoded['videoId'], videoId);
      expect(decoded['startSec'], isNull);
      expect(decoded['endSec'], isNull);
      expect(decoded['title'], isNull);
    });

    test('should handle start/end times as 0', () {
      final code = ShareCodeGenerator.encode(
        videoId: videoId,
        startSec: 0,
        endSec: 0,
      );
      final decoded = ShareCodeGenerator.decode(code);

      // 0 is treated as null in our logic for simplicity/compression
      expect(decoded['startSec'], isNull);
      expect(decoded['endSec'], isNull);
    });

    test('should truncate start/end times if > 65535', () {
      final code = ShareCodeGenerator.encode(
        videoId: videoId,
        startSec: 70000,
        endSec: 70000,
      );
      final decoded = ShareCodeGenerator.decode(code);

      expect(decoded['startSec'], 65535);
      expect(decoded['endSec'], 65535);
    });

    test('should throw error for invalid video ID length', () {
      expect(
        () => ShareCodeGenerator.encode(videoId: 'short'),
        throwsFormatException,
      );
    });

    test('should throw error for invalid code', () {
      expect(
        () => ShareCodeGenerator.decode('invalid_code'),
        throwsFormatException,
      );
    });
  });
}
