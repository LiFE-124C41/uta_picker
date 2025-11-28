// lib/platform/youtube_player/web_player.dart
import 'dart:async';
import '../../platform/stubs/html_stub.dart' if (dart.library.html) 'dart:html'
    as html show document, ScriptElement, IFrameElement, DivElement;
import '../../platform/stubs/js_stub.dart' if (dart.library.js) 'dart:js' as js;
import '../../platform/stubs/ui_web_stub.dart'
    if (dart.library.html) 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebPlayer {
  dynamic _youtubePlayer;
  Timer? _playbackTimer;
  Timer? _apiCheckTimer;
  Timer? _qualityCheckTimer;
  String? _currentVideoId;
  bool _isApiReady = false;
  bool _currentAudioOnlyMode = false;
  final List<_PendingPlayerCreation> _pendingCreations = [];

  String? get currentVideoId => _currentVideoId;

  void initialize() {
    if (!kIsWeb) return;

    // Set up global callback first
    _setupApiCallback();

    // Load YouTube IFrame API script
    final existingScript =
        html.document.querySelector('script[src*="youtube.com/iframe_api"]');
    if (existingScript == null) {
      final script = html.ScriptElement()
        ..src = 'https://www.youtube.com/iframe_api'
        ..async = true;
      html.document.head!.append(script);
    } else {
      // スクリプトが既に存在する場合、APIがロード済みかチェック
      _checkApiReady();
      if (!_isApiReady) {
        _startApiPolling();
      }
    }
  }

  void _setupApiCallback() {
    try {
      js.context['onYouTubeIframeAPIReady'] = () {
        debugPrint('YouTube IFrame API ready callback called');
        _isApiReady = true;
        _apiCheckTimer?.cancel();
        _apiCheckTimer = null;
        // 待機中のプレイヤー作成を実行
        _processPendingCreations();
      };
      debugPrint('YouTube API callback set up');
    } catch (e) {
      debugPrint('Error setting up YouTube API callback: $e');
    }
  }

  void _checkApiReady() {
    try {
      final yt = js.context['YT'];
      if (yt != null && !_isApiReady) {
        debugPrint('YouTube IFrame API detected as ready');
        _isApiReady = true;
        _apiCheckTimer?.cancel();
        _apiCheckTimer = null;
        // 待機中のプレイヤー作成を実行
        _processPendingCreations();
      }
    } catch (e) {
      // API not ready yet
    }
  }

  void _processPendingCreations() {
    if (_pendingCreations.isEmpty) return;

    debugPrint(
        'Processing ${_pendingCreations.length} pending player creation(s)');
    final pending = List<_PendingPlayerCreation>.from(_pendingCreations);
    _pendingCreations.clear();

    for (var item in pending) {
      _createPlayerInternal(
        item.videoId,
        item.startSec,
        item.endSec,
        item.onTimeUpdate,
        item.onEnded,
        audioOnly: item.audioOnly,
      );
    }
  }

  void _startApiPolling() {
    if (_apiCheckTimer != null || _isApiReady) return;

    debugPrint('Starting API polling...');
    _apiCheckTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _checkApiReady();
      if (_isApiReady) {
        timer.cancel();
        _apiCheckTimer = null;
      }
    });
  }

  void prepareDisplayDiv() {
    if (!kIsWeb) return;

    final displayDivId = 'youtube-player-display-div';
    var displayDiv =
        html.document.getElementById(displayDivId) as html.DivElement?;

    if (displayDiv == null) {
      displayDiv = html.DivElement()
        ..id = displayDivId
        ..style.width = '100%'
        ..style.height = '100%';
      html.document.body!.append(displayDiv);

      // Flutterのwidgetツリーに登録
      try {
        ui_web.platformViewRegistry.registerViewFactory(
          'youtube-player-display',
          (int viewId) => displayDiv!,
        );
      } catch (e) {
        // Already registered, ignore
      }
    } else {
      // 既存のdivをクリア
      displayDiv.children.clear();
    }
  }

  void createPlayer(
    String videoId,
    int? startSec,
    int? endSec,
    Function(double) onTimeUpdate,
    VoidCallback? onEnded, {
    bool audioOnly = false,
  }) {
    if (!kIsWeb) return;

    // コールバックが設定されていない場合は設定
    _setupApiCallback();

    // APIがロードされているかチェック
    _checkApiReady();

    if (!_isApiReady) {
      debugPrint(
          'YouTube IFrame API not loaded yet, queuing player creation...');
      // 待機リストに追加
      _pendingCreations.add(_PendingPlayerCreation(
        videoId: videoId,
        startSec: startSec,
        endSec: endSec,
        onTimeUpdate: onTimeUpdate,
        onEnded: onEnded,
        audioOnly: audioOnly,
      ));

      // スクリプトがロードされていない場合はロード
      final existingScript =
          html.document.querySelector('script[src*="youtube.com/iframe_api"]');
      if (existingScript == null) {
        final script = html.ScriptElement()
          ..src = 'https://www.youtube.com/iframe_api'
          ..async = true;
        html.document.head!.append(script);
        debugPrint('YouTube IFrame API script loading...');
      }

      // ポーリングを開始
      _startApiPolling();
      return;
    }

    _createPlayerInternal(videoId, startSec, endSec, onTimeUpdate, onEnded,
        audioOnly: audioOnly);
  }

  void _createPlayerInternal(
    String videoId,
    int? startSec,
    int? endSec,
    Function(double) onTimeUpdate,
    VoidCallback? onEnded, {
    bool audioOnly = false,
  }) {
    if (!kIsWeb) return;

    try {
      final yt = js.context['YT'];

      if (yt == null) {
        debugPrint('YouTube IFrame API still not available');
        return;
      }

      debugPrint('YouTube IFrame API found, creating player...');

      // 既存のプレイヤーがあれば破棄
      if (_youtubePlayer != null) {
        try {
          (_youtubePlayer as js.JsObject).callMethod('destroy');
          _youtubePlayer = null;
        } catch (e) {
          debugPrint('Error destroying player: $e');
        }
      }

      // プレイヤー用のdivを作成
      final apiDivId = 'youtube-player-api';
      final existingApiDiv = html.document.getElementById(apiDivId);
      if (existingApiDiv != null) {
        existingApiDiv.remove();
      }

      final displayDiv =
          html.document.getElementById('youtube-player-display-div');
      if (displayDiv == null) {
        debugPrint('Display div not found, preparing...');
        prepareDisplayDiv();
        Future.delayed(Duration(milliseconds: 100), () {
          _createPlayerInternal(
              videoId, startSec, endSec, onTimeUpdate, onEnded,
              audioOnly: audioOnly);
        });
        return;
      }

      final apiDiv = html.DivElement()
        ..id = apiDivId
        ..style.width = '100%'
        ..style.height = '100%';
      displayDiv.append(apiDiv);

      // プレイヤー設定を構築
      final playerVars = <String, dynamic>{
        'playsinline': 1,
        'rel': 0,
        'enablejsapi': 1,
      };
      // startSecがnullでない場合のみstartを設定
      if (startSec != null) {
        playerVars['start'] = startSec;
      }

      // 音声のみモードの場合、最低解像度を設定してパケット量を削減
      if (audioOnly) {
        playerVars['quality'] = 'tiny'; // 最低解像度（144p相当）
        playerVars['controls'] = 0; // コントロールを非表示
        debugPrint('Audio-only mode: Using lowest quality to reduce bandwidth');
      }

      // 新しいプレイヤーを作成
      final playerConfig = js.JsObject.jsify({
        'videoId': videoId,
        'playerVars': playerVars,
        'events': {
          'onReady': (event) {
            try {
              final player = (event as js.JsObject)['target'];
              // 音声のみモードの場合、解像度を最低に設定
              if (audioOnly) {
                try {
                  player.callMethod('setPlaybackQuality', ['tiny']);
                  // 少し遅延してから再度設定（YouTubeが自動的に品質を変更する場合があるため）
                  Future.delayed(Duration(milliseconds: 500), () {
                    try {
                      player.callMethod('setPlaybackQuality', ['tiny']);
                    } catch (e) {
                      debugPrint(
                          'Error setting playback quality (delayed): $e');
                    }
                  });
                } catch (e) {
                  debugPrint('Error setting playback quality: $e');
                }
              }
              if (startSec != null) {
                player.callMethod('seekTo', [startSec, true]);
              }
              // 自動再生を開始（これが重要）
              player.callMethod('playVideo');

              monitorPlaybackTime(
                  player, startSec, endSec, onTimeUpdate, onEnded);
            } catch (e) {
              debugPrint('Error in onReady: $e');
            }
          },
          'onStateChange': (event) {
            try {
              final jsEvent = event as js.JsObject;
              final state = jsEvent['data'];
              final player = jsEvent['target'];
              if (state == 0) {
                // 終了（ENDED）
                // タブが非アクティブでも確実に検出できるように、onStateChangeでENDEDを処理
                _playbackTimer?.cancel();
                _playbackTimer = null;
                if (onEnded != null) {
                  onEnded();
                }
              } else if (state == 1) {
                // 再生中
                // 音声のみモードの場合、再生開始時に品質を再設定
                if (audioOnly) {
                  try {
                    player.callMethod('setPlaybackQuality', ['tiny']);
                    // 品質チェックタイマーを開始
                    _startQualityCheckTimer(player);
                  } catch (e) {
                    debugPrint(
                        'Error setting playback quality in onStateChange: $e');
                  }
                }
                monitorPlaybackTime(
                    player, startSec, endSec, onTimeUpdate, onEnded);
              }
            } catch (e) {
              debugPrint('Error in onStateChange: $e');
            }
          },
          'onPlaybackQualityChange': (event) {
            // 品質が変更されたときに監視
            if (audioOnly) {
              try {
                final jsEvent = event as js.JsObject;
                final player = jsEvent['target'];
                final quality = jsEvent['data'];
                debugPrint('Playback quality changed to: $quality');
                // tiny以外の品質に変更された場合は再度tinyに設定
                if (quality != null &&
                    quality != 'tiny' &&
                    quality != 'small') {
                  debugPrint('Forcing quality back to tiny...');
                  player.callMethod('setPlaybackQuality', ['tiny']);
                }
              } catch (e) {
                debugPrint('Error handling playback quality change: $e');
              }
            }
          },
          'onError': (event) {
            final jsEvent = event as js.JsObject;
            debugPrint('YouTube player error: ${jsEvent['data']}');
          },
        },
      });

      final playerConstructor = yt['Player'];
      _youtubePlayer = js.JsObject(playerConstructor, [apiDivId, playerConfig]);

      _currentVideoId = videoId;
      _currentAudioOnlyMode = audioOnly;
      debugPrint(
          'YouTube player created for video: $videoId (audioOnly: $audioOnly)');
    } catch (e) {
      debugPrint('Error creating YouTube player: $e');
    }
  }

  void _startQualityCheckTimer(dynamic player) {
    if (!kIsWeb) return;

    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = null;

    if (!_currentAudioOnlyMode) return;

    // 音声のみモードの場合、定期的に品質をチェックして再設定
    // より頻繁にチェック（1秒ごと）して、YouTubeが品質を変更した場合に即座に対応
    _qualityCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      try {
        final jsPlayer = player as js.JsObject;
        final currentQuality = jsPlayer.callMethod('getPlaybackQuality');
        if (currentQuality != null &&
            currentQuality != 'tiny' &&
            currentQuality != 'small' &&
            currentQuality != 'medium') {
          debugPrint('Quality is $currentQuality, forcing to tiny...');
          jsPlayer.callMethod('setPlaybackQuality', ['tiny']);
        }
      } catch (e) {
        // エラーが発生した場合はタイマーを停止
        timer.cancel();
        _qualityCheckTimer = null;
      }
    });
  }

  void monitorPlaybackTime(
    dynamic player,
    int? startSec,
    int? endSec,
    Function(double) onTimeUpdate,
    VoidCallback? onEnded,
  ) {
    if (!kIsWeb) return;

    // 既存のTimerをキャンセル
    _playbackTimer?.cancel();
    _playbackTimer = null;

    _playbackTimer = Timer.periodic(Duration(milliseconds: 500), (t) {
      try {
        final jsPlayer = player as js.JsObject;
        final currentTime =
            (jsPlayer.callMethod('getCurrentTime') as num).toDouble();
        onTimeUpdate(currentTime);

        // endSecがnullでない場合のみ、終了時刻をチェック
        if (endSec != null && currentTime >= endSec) {
          // 終了時刻に達したら停止
          // stopVideoを呼び出すことで、onStateChangeでENDED状態を検出できるようにする
          try {
            jsPlayer.callMethod('stopVideo');
          } catch (e) {
            debugPrint('Error stopping video: $e');
            // stopVideoが失敗した場合は、pauseVideoを試す
            try {
              jsPlayer.callMethod('pauseVideo');
            } catch (e2) {
              debugPrint('Error pausing video: $e2');
            }
          }
          _playbackTimer?.cancel();
          _playbackTimer = null;

          // タイマーが動作している場合（タブがアクティブな場合）は、直接onEndedを呼ぶ
          // タブが非アクティブでタイマーがスロットルされている場合は、
          // onStateChangeでENDEDを検出する（ただし、stopVideoがENDEDを発火するかは不明）
          // 両方の方法で確実に処理できるようにする
          if (onEnded != null) {
            onEnded();
          }
        }
      } catch (e) {
        debugPrint('Error monitoring playback time: $e');
        _playbackTimer?.cancel();
        _playbackTimer = null;
      }
    });
  }

  void pause() {
    if (kIsWeb && _youtubePlayer != null) {
      try {
        (_youtubePlayer as js.JsObject).callMethod('pauseVideo');
      } catch (e) {
        // Ignore
      }
    }
  }

  void dispose() {
    _playbackTimer?.cancel();
    _apiCheckTimer?.cancel();
    _qualityCheckTimer?.cancel();
    if (kIsWeb && _youtubePlayer != null) {
      try {
        (_youtubePlayer as js.JsObject).callMethod('destroy');
      } catch (e) {
        // Ignore
      }
    }
  }

  Widget buildPlayerWidget([String? videoId]) {
    final displayVideoId = videoId ?? _currentVideoId;
    if (displayVideoId == null) {
      return const Center(child: Text('動画を選択してください'));
    }

    if (!kIsWeb) {
      return const Center(child: Text('WebPlayerはWebプラットフォームでのみ利用可能です'));
    }

    final viewType = 'youtube-player-display';

    final displayDiv =
        html.document.getElementById('youtube-player-display-div');
    if (displayDiv == null) {
      prepareDisplayDiv();
    }

    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final div =
              html.document.getElementById('youtube-player-display-div');
          if (div != null) {
            return div;
          }
          final newDiv = html.DivElement()
            ..id = 'youtube-player-display-div'
            ..style.width = '100%'
            ..style.height = '100%';
          html.document.body!.append(newDiv);
          return newDiv;
        },
      );
    } catch (e) {
      // Already registered, ignore
    }

    return HtmlElementView(viewType: viewType);
  }

  Widget buildIframeWidget(String videoId) {
    if (!kIsWeb) {
      return const Center(child: Text('WebPlayerはWebプラットフォームでのみ利用可能です'));
    }

    final viewType = 'youtube-iframe-$videoId';

    try {
      String src =
          'https://www.youtube.com/embed/$videoId?enablejsapi=1&playsinline=1&rel=0';

      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => iframe,
      );
    } catch (e) {
      // Already registered, ignore
    }

    return HtmlElementView(viewType: viewType);
  }

  /// iframeのポインターイベントを無効化（AlertDialog表示時などに使用）
  void disablePointerEvents() {
    if (!kIsWeb) return;
    try {
      // すべてのYouTube iframeを検索
      final iframes =
          html.document.querySelectorAll('iframe[src*="youtube.com"]');
      for (var iframe in iframes) {
        (iframe as html.IFrameElement).style.pointerEvents = 'none';
      }
      // YouTube Player APIで作成されたプレイヤーのiframeも無効化
      final displayDiv =
          html.document.getElementById('youtube-player-display-div');
      if (displayDiv != null) {
        final playerIframes = displayDiv.querySelectorAll('iframe');
        for (var iframe in playerIframes) {
          (iframe as html.IFrameElement).style.pointerEvents = 'none';
        }
      }
    } catch (e) {
      debugPrint('Error disabling pointer events: $e');
    }
  }

  /// iframeのポインターイベントを有効化
  void enablePointerEvents() {
    if (!kIsWeb) return;
    try {
      // すべてのYouTube iframeを検索
      final iframes =
          html.document.querySelectorAll('iframe[src*="youtube.com"]');
      for (var iframe in iframes) {
        (iframe as html.IFrameElement).style.pointerEvents = 'auto';
      }
      // YouTube Player APIで作成されたプレイヤーのiframeも有効化
      final displayDiv =
          html.document.getElementById('youtube-player-display-div');
      if (displayDiv != null) {
        final playerIframes = displayDiv.querySelectorAll('iframe');
        for (var iframe in playerIframes) {
          (iframe as html.IFrameElement).style.pointerEvents = 'auto';
        }
      }
    } catch (e) {
      debugPrint('Error enabling pointer events: $e');
    }
  }
}

class _PendingPlayerCreation {
  final String videoId;
  final int? startSec;
  final int? endSec;
  final Function(double) onTimeUpdate;
  final VoidCallback? onEnded;
  final bool audioOnly;

  _PendingPlayerCreation({
    required this.videoId,
    this.startSec,
    this.endSec,
    required this.onTimeUpdate,
    this.onEnded,
    this.audioOnly = false,
  });
}
