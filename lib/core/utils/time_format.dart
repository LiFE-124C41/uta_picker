// lib/core/utils/time_format.dart
class TimeFormat {
  /// 秒数を'00:00'形式（分:秒）または'00:00:00'形式（時:分:秒）の文字列に変換
  /// 60分未満: 90 -> "01:30", 30 -> "00:30"
  /// 60分以上: 4072 -> "01:07:52", 3600 -> "01:00:00"
  static String formatTimeString(int seconds) {
    if (seconds >= 3600) {
      // 60分以上の場合、時:分:秒形式
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      // 60分未満の場合、分:秒形式
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

