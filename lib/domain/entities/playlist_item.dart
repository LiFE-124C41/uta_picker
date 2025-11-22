// lib/domain/entities/playlist_item.dart
class PlaylistItem {
  String videoId;
  int? startSec; // nullの場合は動画の最初から
  int? endSec; // nullの場合は動画の最後まで
  String? videoTitle; // 動画タイトル
  String? songTitle; // 楽曲タイトル

  PlaylistItem({
    required this.videoId,
    this.startSec,
    this.endSec,
    this.videoTitle,
    this.songTitle,
  });

  Map<String, dynamic> toJson() => {
        'video_id': videoId,
        'start_sec': startSec,
        'end_sec': endSec,
        'video_title': videoTitle,
        'song_title': songTitle,
      };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    // 後方互換性: 古いデータにtitleがあればsongTitleにマッピング
    final songTitle = json['song_title'] as String? ?? json['title'] as String?;
    return PlaylistItem(
      videoId: json['video_id'] as String,
      startSec: json['start_sec'] as int?,
      endSec: json['end_sec'] as int?,
      videoTitle: json['video_title'] as String?,
      songTitle: songTitle,
    );
  }
}
