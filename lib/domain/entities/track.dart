// lib/domain/entities/track.dart
class Track {
  int? id;
  String videoId;
  String videoTitle;
  int startSec;
  int? endSec;
  String songTitle;
  String recordedAt;
  String? note;

  Track({
    this.id,
    required this.videoId,
    required this.videoTitle,
    required this.startSec,
    this.endSec,
    required this.songTitle,
    required this.recordedAt,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'video_id': videoId,
        'video_title': videoTitle,
        'start_sec': startSec,
        'end_sec': endSec,
        'song_title': songTitle,
        'recorded_at': recordedAt,
        'note': note,
      };

  factory Track.fromMap(Map<String, dynamic> map) => Track(
        id: map['id'] as int?,
        videoId: map['video_id'] as String,
        videoTitle: map['video_title'] as String,
        startSec: map['start_sec'] as int,
        endSec: map['end_sec'] as int?,
        songTitle: map['song_title'] as String,
        recordedAt: map['recorded_at'] as String,
        note: map['note'] as String?,
      );

  Map<String, dynamic> toJson() => toMap();
  factory Track.fromJson(Map<String, dynamic> json) => Track.fromMap(json);
}

