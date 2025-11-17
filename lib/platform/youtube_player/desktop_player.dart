// lib/platform/youtube_player/desktop_player.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import '../stubs/webview_stub.dart'
    if (dart.library.io) 'package:webview_flutter/webview_flutter.dart'
    as webview;

class DesktopPlayer {
  dynamic _webController;
  
  void initialize() {
    if (kIsWeb) return;
    
    try {
      final controller = webview.WebViewController()
        ..setJavaScriptMode(webview.JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'TimeChannel',
          onMessageReceived: (dynamic msg) {
            // Time update is handled by the caller
          },
        )
        ..loadRequest(Uri.parse('about:blank'));
      _webController = controller;
    } catch (e) {
      // Ignore errors
    }
  }
  
  String playerHtmlWithTimeRange(String videoId, int startSec, int endSec) {
    return '''
    <!DOCTYPE html>
    <html>
    <body style="margin:0">
      <div id="player"></div>
      <script>
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        document.body.appendChild(tag);
        var player;
        var endSec = $endSec;
        function onYouTubeIframeAPIReady() {
          player = new YT.Player('player', {
            height: '100%',
            width: '100%',
            videoId: '$videoId',
            playerVars: { 'playsinline': 1, 'rel': 0, 'start': $startSec },
            events: { 
              'onReady': onPlayerReady,
              'onStateChange': onStateChange
            }
          });
        }
        function onPlayerReady(event) {
          player.seekTo($startSec, true);
          player.playVideo();
          monitorTime();
        }
        function onStateChange(event) {
          if (event.data == YT.PlayerState.PLAYING) {
            monitorTime();
          }
        }
        function monitorTime() {
          var interval = setInterval(function(){
            try {
              if(player && player.getCurrentTime){
                var t = player.getCurrentTime();
                TimeChannel.postMessage(String(t));
                if(t >= endSec) {
                  player.pauseVideo();
                  clearInterval(interval);
                }
              }
            } catch(e){
              clearInterval(interval);
            }
          }, 500);
        }
        function seekTo(sec){
          if(player) player.seekTo(sec, true);
        }
      </script>
    </body>
    </html>
    ''';
  }
  
  String playerHtml(String videoId) {
    return '''
    <!DOCTYPE html>
    <html>
    <body style="margin:0">
      <div id="player"></div>
      <script>
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        document.body.appendChild(tag);
        var player;
        function onYouTubeIframeAPIReady() {
          player = new YT.Player('player', {
            height: '100%',
            width: '100%',
            videoId: '$videoId',
            playerVars: { 'playsinline': 1, 'rel': 0 },
            events: { 'onReady': onPlayerReady }
          });
        }
        function onPlayerReady(event) {
          setInterval(function(){
            try {
              if(player && player.getCurrentTime){
                var t = player.getCurrentTime();
                TimeChannel.postMessage(String(t));
              }
            } catch(e){}
          }, 400);
        }
        function seekTo(sec){
          if(player) player.seekTo(sec, true);
        }
      </script>
    </body>
    </html>
    ''';
  }
  
  void loadVideo(String videoId) {
    if (kIsWeb || _webController == null) return;
    final htmlStr = playerHtml(videoId);
    final url = Uri.dataFromString(htmlStr,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    _webController.loadRequest(url);
  }
  
  void playTimeRange(String videoId, int startSec, int endSec) {
    if (kIsWeb || _webController == null) return;
    final htmlStr = playerHtmlWithTimeRange(videoId, startSec, endSec);
    final url = Uri.dataFromString(htmlStr,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    _webController.loadRequest(url);
  }
  
  Future<void> seekTo(double seconds) async {
    if (kIsWeb || _webController == null) return;
    await _webController.runJavaScript('seekTo($seconds)');
  }
  
  dynamic get controller => _webController;
  
  Widget buildWebView() {
    if (!kIsWeb && _webController != null) {
      try {
        return webview.WebViewWidget(controller: _webController);
      } catch (e) {
        return const Center(child: Text('WebView not available'));
      }
    }
    return const Center(child: Text('WebView not available'));
  }
}

