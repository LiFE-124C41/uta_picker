// lib/domain/entities/playlist_item.dart
class PlaylistItem {
  String videoId;
  int startSec;
  int endSec;
  String? title; // オプションのタイトル

  PlaylistItem({
    required this.videoId,
    required this.startSec,
    required this.endSec,
    this.title,
  });

  Map<String, dynamic> toJson() => {
        'video_id': videoId,
        'start_sec': startSec,
        'end_sec': endSec,
        'title': title,
      };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => PlaylistItem(
        videoId: json['video_id'] as String,
        startSec: json['start_sec'] as int,
        endSec: json['end_sec'] as int,
        title: json['title'] as String?,
      );
}

