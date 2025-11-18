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
  String? _currentVideoId;
  bool _isApiReady = false;
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
        print('YouTube IFrame API ready callback called');
        _isApiReady = true;
        _apiCheckTimer?.cancel();
        _apiCheckTimer = null;
        // 待機中のプレイヤー作成を実行
        _processPendingCreations();
      };
      print('YouTube API callback set up');
    } catch (e) {
      print('Error setting up YouTube API callback: $e');
    }
  }

  void _checkApiReady() {
    try {
      final YT = js.context['YT'];
      if (YT != null && !_isApiReady) {
        print('YouTube IFrame API detected as ready');
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

    print('Processing ${_pendingCreations.length} pending player creation(s)');
    final pending = List<_PendingPlayerCreation>.from(_pendingCreations);
    _pendingCreations.clear();

    for (var item in pending) {
      _createPlayerInternal(
        item.videoId,
        item.startSec,
        item.endSec,
        item.onTimeUpdate,
        item.onEnded,
      );
    }
  }

  void _startApiPolling() {
    if (_apiCheckTimer != null || _isApiReady) return;

    print('Starting API polling...');
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
        ui_web.PlatformViewRegistry.registerViewFactory(
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
    int startSec,
    int endSec,
    Function(double) onTimeUpdate,
    VoidCallback? onEnded,
  ) {
    if (!kIsWeb) return;

    // コールバックが設定されていない場合は設定
    _setupApiCallback();

    // APIがロードされているかチェック
    _checkApiReady();

    if (!_isApiReady) {
      print('YouTube IFrame API not loaded yet, queuing player creation...');
      // 待機リストに追加
      _pendingCreations.add(_PendingPlayerCreation(
        videoId: videoId,
        startSec: startSec,
        endSec: endSec,
        onTimeUpdate: onTimeUpdate,
        onEnded: onEnded,
      ));

      // スクリプトがロードされていない場合はロード
      final existingScript =
          html.document.querySelector('script[src*="youtube.com/iframe_api"]');
      if (existingScript == null) {
        final script = html.ScriptElement()
          ..src = 'https://www.youtube.com/iframe_api'
          ..async = true;
        html.document.head!.append(script);
        print('YouTube IFrame API script loading...');
      }

      // ポーリングを開始
      _startApiPolling();
      return;
    }

    _createPlayerInternal(videoId, startSec, endSec, onTimeUpdate, onEnded);
  }

  void _createPlayerInternal(
    String videoId,
    int startSec,
    int endSec,
    Function(double) onTimeUpdate,
    VoidCallback? onEnded,
  ) {
    if (!kIsWeb) return;

    try {
      final YT = js.context['YT'];

      if (YT == null) {
        print('YouTube IFrame API still not available');
        return;
      }

      print('YouTube IFrame API found, creating player...');

      // 既存のプレイヤーがあれば破棄
      if (_youtubePlayer != null) {
        try {
          (_youtubePlayer as js.JsObject).callMethod('destroy');
          _youtubePlayer = null;
        } catch (e) {
          print('Error destroying player: $e');
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
        print('Display div not found, preparing...');
        prepareDisplayDiv();
        Future.delayed(Duration(milliseconds: 100), () {
          _createPlayerInternal(
              videoId, startSec, endSec, onTimeUpdate, onEnded);
        });
        return;
      }

      final apiDiv = html.DivElement()
        ..id = apiDivId
        ..style.width = '100%'
        ..style.height = '100%';
      displayDiv.append(apiDiv);

      // 新しいプレイヤーを作成
      final playerConfig = js.JsObject.jsify({
        'videoId': videoId,
        'playerVars': {
          'playsinline': 1,
          'rel': 0,
          'start': startSec,
          'enablejsapi': 1,
        },
        'events': {
          'onReady': (event) {
            try {
              final player = (event as js.JsObject)['target'];
              player.callMethod('seekTo', [startSec, true]);
              player.callMethod('playVideo');
              monitorPlaybackTime(
                  player, startSec, endSec, onTimeUpdate, onEnded);
            } catch (e) {
              print('Error in onReady: $e');
            }
          },
          'onStateChange': (event) {
            try {
              final jsEvent = event as js.JsObject;
              final state = jsEvent['data'];
              final player = jsEvent['target'];
              if (state == 1) {
                // 再生中
                monitorPlaybackTime(
                    player, startSec, endSec, onTimeUpdate, onEnded);
              }
            } catch (e) {
              print('Error in onStateChange: $e');
            }
          },
          'onError': (event) {
            final jsEvent = event as js.JsObject;
            print('YouTube player error: ${jsEvent['data']}');
          },
        },
      });

      final PlayerConstructor = YT['Player'];
      _youtubePlayer = js.JsObject(PlayerConstructor, [apiDivId, playerConfig]);

      _currentVideoId = videoId;
      print('YouTube player created for video: $videoId');
    } catch (e) {
      print('Error creating YouTube player: $e');
    }
  }

  void monitorPlaybackTime(
    dynamic player,
    int startSec,
    int endSec,
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

        if (currentTime >= endSec) {
          // 終了時刻に達したら停止
          try {
            jsPlayer.callMethod('pauseVideo');
          } catch (e) {
            print('Error pausing video: $e');
          }
          _playbackTimer?.cancel();
          _playbackTimer = null;

          if (onEnded != null) {
            onEnded();
          }
        }
      } catch (e) {
        print('Error monitoring playback time: $e');
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
      ui_web.PlatformViewRegistry.registerViewFactory(
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

      ui_web.PlatformViewRegistry.registerViewFactory(
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
      print('Error disabling pointer events: $e');
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
      print('Error enabling pointer events: $e');
    }
  }
}

class _PendingPlayerCreation {
  final String videoId;
  final int startSec;
  final int endSec;
  final Function(double) onTimeUpdate;
  final VoidCallback? onEnded;

  _PendingPlayerCreation({
    required this.videoId,
    required this.startSec,
    required this.endSec,
    required this.onTimeUpdate,
    this.onEnded,
  });
}
