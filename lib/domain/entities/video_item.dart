// lib/domain/entities/video_item.dart
class VideoItem {
  final String videoId;
  final String title;
  final String publishedAt;
  
  VideoItem({
    required this.videoId,
    required this.title,
    required this.publishedAt,
  });
  
  factory VideoItem.fromJson(Map<String, dynamic> json) => VideoItem(
        videoId: json['videoId'] as String,
        title: json['title'] as String,
        publishedAt: json['publishedAt'] as String,
      );
  
  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'publishedAt': publishedAt,
      };
}

