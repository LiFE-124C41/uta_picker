// lib/core/utils/youtube_url_parser.dart

/// YouTubeのURLからvideoIdを抽出するユーティリティクラス
class YoutubeUrlParser {
  /// YouTubeのURLまたはvideoIdからvideoIdを抽出する
  /// 
  /// サポートするURL形式:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtube.com/watch?v=VIDEO_ID
  /// - https://www.youtube.com/live/VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://m.youtube.com/watch?v=VIDEO_ID
  /// 
  /// URLでない場合は、そのまま返す（既にvideoIdの場合）
  static String? extractVideoId(String input) {
    if (input.isEmpty) return null;
    
    final trimmed = input.trim();
    
    // 既にvideoId形式（11文字の英数字とハイフン、アンダースコア）の場合はそのまま返す
    if (_isValidVideoId(trimmed)) {
      return trimmed;
    }
    
    // URL形式の場合、videoIdを抽出
    try {
      final uri = Uri.parse(trimmed);
      
      // youtu.be形式: https://youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final videoId = pathSegments[0].split('?')[0];
          if (_isValidVideoId(videoId)) {
            return videoId;
          }
        }
      }
      
      // youtube.com/live形式: https://www.youtube.com/live/VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.pathSegments.contains('live')) {
        final liveIndex = uri.pathSegments.indexOf('live');
        if (liveIndex >= 0 && liveIndex + 1 < uri.pathSegments.length) {
          final videoId = uri.pathSegments[liveIndex + 1].split('?')[0];
          if (_isValidVideoId(videoId)) {
            return videoId;
          }
        }
      }
      
      // youtube.com/watch形式: https://www.youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.pathSegments.contains('watch')) {
        final videoId = uri.queryParameters['v'];
        if (videoId != null && _isValidVideoId(videoId)) {
          return videoId;
        }
      }
    } catch (e) {
      // URLパースに失敗した場合は、そのまま返す（既にvideoIdの可能性）
      return trimmed;
    }
    
    return null;
  }
  
  /// videoIdが有効な形式かどうかをチェック
  /// YouTubeのvideoIdは通常11文字の英数字とハイフン、アンダースコアで構成される
  static bool _isValidVideoId(String id) {
    if (id.length != 11) return false;
    // 英数字、ハイフン、アンダースコアのみ
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id);
  }
}

