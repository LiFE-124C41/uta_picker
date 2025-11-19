// lib/core/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// アナリティクスサービスクラス
/// Firebase Analyticsを使用してイベントをトラッキングします
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// Firebase Analyticsを初期化
  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Analytics initialization failed: $e');
      }
    }
  }

  /// FirebaseAnalyticsインスタンスを取得
  static FirebaseAnalytics? get analytics => _analytics;

  /// FirebaseAnalyticsObserverを取得
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// ページビューを記録
  static Future<void> logPageView(String pageName) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: pageName);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log page view: $e');
      }
    }
  }

  /// プレイリストアイテムを追加したイベント
  static Future<void> logPlaylistItemAdded({
    String? videoId,
    int? startSec,
    int? endSec,
  }) async {
    if (_analytics == null) return;
    try {
      final parameters = <String, Object>{};
      if (videoId != null) parameters['video_id'] = videoId;
      if (startSec != null) parameters['start_sec'] = startSec;
      if (endSec != null) parameters['end_sec'] = endSec;
      if (endSec != null && startSec != null) {
        parameters['duration_sec'] = endSec - startSec;
      }
      await _analytics!.logEvent(
        name: 'playlist_item_added',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log playlist item added: $e');
      }
    }
  }

  /// プレイリストを再生したイベント
  static Future<void> logPlaylistPlayed({
    int? itemCount,
  }) async {
    if (_analytics == null) return;
    try {
      final parameters = <String, Object>{};
      if (itemCount != null) parameters['item_count'] = itemCount;
      await _analytics!.logEvent(
        name: 'playlist_played',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log playlist played: $e');
      }
    }
  }

  /// 動画を選択したイベント
  static Future<void> logVideoSelected({
    String? videoId,
  }) async {
    if (_analytics == null) return;
    try {
      final parameters = <String, Object>{};
      if (videoId != null) parameters['video_id'] = videoId;
      await _analytics!.logEvent(
        name: 'video_selected',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log video selected: $e');
      }
    }
  }

  /// CSVをエクスポートしたイベント
  static Future<void> logCsvExported({
    int? itemCount,
  }) async {
    if (_analytics == null) return;
    try {
      final parameters = <String, Object>{};
      if (itemCount != null) parameters['item_count'] = itemCount;
      await _analytics!.logEvent(
        name: 'csv_exported',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log CSV exported: $e');
      }
    }
  }

  /// CSVをインポートしたイベント
  static Future<void> logCsvImported({
    int? itemCount,
  }) async {
    if (_analytics == null) return;
    try {
      final parameters = <String, Object>{};
      if (itemCount != null) parameters['item_count'] = itemCount;
      await _analytics!.logEvent(
        name: 'csv_imported',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log CSV imported: $e');
      }
    }
  }

  /// JSONからプレイリストをインポートしたイベント
  static Future<void> logJsonImported({
    int? videoCount,
  }) async {
    if (_analytics == null) return;
    try {
      final parameters = <String, Object>{};
      if (videoCount != null) parameters['video_count'] = videoCount;
      await _analytics!.logEvent(
        name: 'json_imported',
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log JSON imported: $e');
      }
    }
  }

  /// 開発者モードを有効化したイベント
  static Future<void> logDeveloperModeEnabled() async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'developer_mode_enabled',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log developer mode enabled: $e');
      }
    }
  }

  /// 音声のみモードを切り替えたイベント
  static Future<void> logAudioOnlyModeToggled({
    required bool enabled,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'audio_only_mode_toggled',
        parameters: {
          'enabled': enabled,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log audio only mode toggled: $e');
      }
    }
  }

  /// カスタムイベントを記録
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event: $e');
      }
    }
  }
}

