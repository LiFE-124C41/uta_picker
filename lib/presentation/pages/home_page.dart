// lib/presentation/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../platform/stubs/io_stub.dart' if (dart.library.io) 'dart:io'
    as io_platform;
import 'dart:html' as html show Blob, Url, AnchorElement;

import '../../../domain/entities/video_item.dart';
import '../../../domain/entities/playlist_item.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_repository_impl.dart';
import '../../../platform/youtube_player/web_player.dart';
import '../../../platform/youtube_player/desktop_player.dart';
import '../../../core/utils/csv_export.dart';

class HomePage extends StatefulWidget {
  final PlaylistRepository playlistRepository;

  const HomePage({
    Key? key,
    required this.playlistRepository,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<VideoItem> videos = [];
  int? selectedIndex;
  double currentSec = 0;
  String? _currentVideoId;
  List<PlaylistItem> playlist = [];
  int? currentPlaylistIndex;
  bool isPlayingPlaylist = false;
  bool _isPlaying = false;
  bool _isDeveloperModeEnabled = false;
  int _developerModeTapCount = 0;
  Timer? _developerModeTapTimer;

  late WebPlayer _webPlayer;
  late DesktopPlayer _desktopPlayer;
  Timer? _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _webPlayer = WebPlayer();
    _desktopPlayer = DesktopPlayer();

    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize playlist repository if it has initialize method
    if (widget.playlistRepository is PlaylistRepositoryImpl) {
      await (widget.playlistRepository as PlaylistRepositoryImpl).initialize();
    }

    if (!kIsWeb) {
      _desktopPlayer.initialize();
    } else {
      _webPlayer.initialize();
    }

    await _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final loadedPlaylist = await widget.playlistRepository.getPlaylist();
    setState(() {
      playlist = loadedPlaylist;
    });
  }

  void loadSelectedVideoToWebview() async {
    if (selectedIndex == null) return;
    final v = videos[selectedIndex!];

    if (kIsWeb) {
      _currentVideoId = v.videoId;
      setState(() {
        _isPlaying = false;
      });
    } else {
      _desktopPlayer.loadVideo(v.videoId);
    }
  }

  void _playTimeRange(String videoId, int startSec, int endSec) {
    if (kIsWeb) {
      _playTimeRangeWeb(videoId, startSec, endSec);
    } else {
      _playTimeRangeDesktop(videoId, startSec, endSec);
    }
  }

  void _playTimeRangeWeb(String videoId, int startSec, int endSec) {
    if (!kIsWeb) return;

    _webPlayer.prepareDisplayDiv();
    setState(() {
      _currentVideoId = videoId;
      _isPlaying = true;
    });

    _webPlayer.createPlayer(
      videoId,
      startSec,
      endSec,
      (double time) {
        if (mounted) {
          setState(() {
            currentSec = time;
          });
        }
      },
      () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
          if (isPlayingPlaylist && currentPlaylistIndex != null) {
            _playNextPlaylistItem();
          } else {
            setState(() {
              isPlayingPlaylist = false;
              currentPlaylistIndex = null;
            });
          }
        }
      },
    );
  }

  void _playTimeRangeDesktop(String videoId, int startSec, int endSec) {
    if (kIsWeb) return;
    _desktopPlayer.playTimeRange(videoId, startSec, endSec);

    // TimeChannelからの更新を監視
    _startTimeUpdateTimer();
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer?.cancel();
    // DesktopではWebViewのJavaScriptChannelから更新される
    // ここでは簡易的にタイマーで更新（実際の実装ではJavaScriptChannelを使用）
  }

  void _playNextPlaylistItem() {
    if (currentPlaylistIndex == null || playlist.isEmpty) return;

    final nextIndex = currentPlaylistIndex! + 1;
    if (nextIndex >= playlist.length) {
      setState(() {
        isPlayingPlaylist = false;
        currentPlaylistIndex = null;
      });
      return;
    }

    setState(() {
      currentPlaylistIndex = nextIndex;
    });

    final item = playlist[nextIndex];
    _playTimeRange(item.videoId, item.startSec, item.endSec);
  }

  Future<void> exportCsv() async {
    if (playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プレイリストが空です')),
      );
      return;
    }

    final sb = StringBuffer();
    sb.writeln('video_title,song_title,video_id,start_sec,end_sec,link');
    for (var item in playlist) {
      final link = 'https://youtu.be/${item.videoId}?t=${item.startSec}';
      sb.writeln(
          '${CsvExport.escape(item.videoTitle ?? '')},${CsvExport.escape(item.songTitle ?? '')},${item.videoId},${item.startSec},${item.endSec},$link');
    }

    if (kIsWeb) {
      final blob = html.Blob([sb.toString()], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'playlist_export.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('CSVファイルをダウンロードしました')));
    } else {
      final dir = await getApplicationSupportDirectory();
      final out = io_platform.File(
          '${dir.path}${io_platform.Platform.pathSeparator}playlist_export.csv');
      await out.writeAsString(sb.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exported to ${out.path}')));
    }
  }

  void _playPlaylist() {
    if (playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プレイリストが空です')),
      );
      return;
    }

    setState(() {
      isPlayingPlaylist = true;
      currentPlaylistIndex = 0;
    });

    final item = playlist[0];
    _playTimeRange(item.videoId, item.startSec, item.endSec);
  }

  void _stopPlaylist() {
    _timeUpdateTimer?.cancel();
    _webPlayer.pause();

    setState(() {
      _isPlaying = false;
      isPlayingPlaylist = false;
      currentPlaylistIndex = null;
    });
  }

  void _handleTitleTap() {
    _developerModeTapTimer?.cancel();
    _developerModeTapCount++;

    if (_developerModeTapCount >= 5) {
      setState(() {
        _isDeveloperModeEnabled = true;
        _developerModeTapCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開発者モードが有効になりました')),
      );
    } else {
      // 2秒以内に次のタップがないとカウントをリセット
      _developerModeTapTimer = Timer(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _developerModeTapCount = 0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _developerModeTapTimer?.cancel();
    _webPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = Container(
      width: 320,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('プレイリスト', style: TextStyle(fontSize: 18)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (playlist.isNotEmpty) ...[
                      IconButton(
                        icon: Icon(
                          isPlayingPlaylist ? Icons.stop : Icons.play_arrow,
                        ),
                        onPressed:
                            isPlayingPlaylist ? _stopPlaylist : _playPlaylist,
                        tooltip: isPlayingPlaylist ? '停止' : '再生',
                      ),
                      if (isPlayingPlaylist && currentPlaylistIndex != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(
                            '${currentPlaylistIndex! + 1} / ${playlist.length}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () async {
                        await Navigator.pushNamed(
                            context, '/playlist-management');
                        await _loadPlaylist();
                      },
                      tooltip: 'プレイリスト管理',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (playlist.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: playlist.length,
                itemBuilder: (context, idx) {
                  final item = playlist[idx];
                  final isCurrent =
                      isPlayingPlaylist && currentPlaylistIndex == idx;
                  final displayTitle =
                      item.songTitle ?? item.videoTitle ?? '動画 ${item.videoId}';
                  final subtitleParts = <String>[];
                  if (item.videoTitle != null &&
                      item.videoTitle != item.songTitle) {
                    subtitleParts.add('動画: ${item.videoTitle}');
                  }
                  subtitleParts.add(
                      '${item.videoId} @ ${item.startSec}s - ${item.endSec}s');
                  return ListTile(
                    title: Text(
                      displayTitle,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Colors.blue : null,
                      ),
                    ),
                    subtitle: Text(subtitleParts.join('\n')),
                    trailing: IconButton(
                      icon: Icon(Icons.play_arrow, size: 20),
                      onPressed: () {
                        setState(() {
                          isPlayingPlaylist = true;
                          currentPlaylistIndex = idx;
                        });
                        _playTimeRange(
                            item.videoId, item.startSec, item.endSec);
                      },
                      tooltip: '再生',
                    ),
                    onTap: () {
                      setState(() {
                        isPlayingPlaylist = true;
                        currentPlaylistIndex = idx;
                      });
                      _playTimeRange(item.videoId, item.startSec, item.endSec);
                    },
                  );
                },
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('プレイリストが空です\n管理画面で追加してください'),
            ),
        ],
      ),
    );

    final right = Column(
      children: [
        // 動画リスト表示セクション
        if (videos.isNotEmpty)
          Container(
            height: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '動画リスト (${videos.length})',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, idx) {
                      final video = videos[idx];
                      final isSelected = selectedIndex == idx;
                      return ListTile(
                        title: Text(
                          video.title,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'ID: ${video.videoId}',
                          style: TextStyle(fontSize: 10),
                        ),
                        selected: isSelected,
                        trailing: IconButton(
                          icon: Icon(Icons.playlist_add, size: 20),
                          onPressed: () => _showCreatePlaylistItemDialog(video),
                          tooltip: 'プレイリストに追加',
                        ),
                        onTap: () {
                          setState(() {
                            selectedIndex = idx;
                          });
                          loadSelectedVideoToWebview();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            color: Colors.black12,
            child: kIsWeb
                ? (_currentVideoId != null
                    ? _buildWebPlayer()
                    : const Center(child: Text('動画を選択してください')))
                : _desktopPlayer.buildWebView(),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Text('UtaPicker'),
        ),
        actions: [
          if (_isDeveloperModeEnabled)
            IconButton(
              icon: Icon(Icons.file_upload),
              onPressed: () async {
                await Navigator.pushNamed(context, '/playlist-import');
                await _loadPlaylist();
              },
              tooltip: 'JSONからプレイリストを作成',
            ),
        ],
      ),
      body: Row(children: [left, Expanded(child: right)]),
    );
  }

  Widget _buildWebPlayer() {
    if (_currentVideoId == null) {
      return const Center(child: Text('動画を選択してください'));
    }

    // 再生中（プレイリスト再生または通常再生）の場合はbuildPlayerWidgetを使用
    if (_isPlaying || (isPlayingPlaylist && currentPlaylistIndex != null)) {
      return _webPlayer.buildPlayerWidget(_currentVideoId);
    }

    return _webPlayer.buildIframeWidget(_currentVideoId!);
  }

  /// '00:00'形式（分:秒）の文字列を秒数に変換
  /// 例: "01:30" -> 90, "00:30" -> 30
  int? _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) return null;
    if (seconds < 0 || seconds >= 60) return null;
    if (minutes < 0) return null;

    return minutes * 60 + seconds;
  }

  /// 動画からプレイリストアイテムを作成するダイアログを表示
  Future<void> _showCreatePlaylistItemDialog(VideoItem video) async {
    final startSecController = TextEditingController();
    final endSecController = TextEditingController();
    final videoTitleController = TextEditingController(text: video.title);
    final songTitleController = TextEditingController();

    if (kIsWeb) {
      _webPlayer.disablePointerEvents();
    }
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('プレイリストに追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '動画: ${video.title}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  '動画ID: ${video.videoId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: startSecController,
                  decoration: InputDecoration(
                    labelText: '開始時刻（分:秒）',
                    hintText: '例: 00:30',
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: endSecController,
                  decoration: InputDecoration(
                    labelText: '終了時刻（分:秒）',
                    hintText: '例: 01:30',
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: videoTitleController,
                  decoration: InputDecoration(
                    labelText: '動画タイトル（オプション）',
                    hintText: '例: YouTube動画のタイトル',
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: songTitleController,
                  decoration: InputDecoration(
                    labelText: '楽曲タイトル（オプション）',
                    hintText: '例: 曲名',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (kIsWeb) {
                  _webPlayer.enablePointerEvents();
                }
                Navigator.pop(context, false);
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (kIsWeb) {
                  _webPlayer.enablePointerEvents();
                }
                Navigator.pop(context, true);
              },
              child: Text('追加'),
            ),
          ],
        ),
      );

      if (result == true) {
        final startSecStr = startSecController.text.trim();
        final endSecStr = endSecController.text.trim();
        final videoTitle = videoTitleController.text.trim();
        final songTitle = songTitleController.text.trim();

        if (startSecStr.isEmpty || endSecStr.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('開始時刻と終了時刻は必須です')),
          );
          return;
        }

        final startSec = _parseTimeString(startSecStr);
        final endSec = _parseTimeString(endSecStr);

        if (startSec == null || endSec == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('開始時刻と終了時刻は「分:秒」形式（例: 00:30）で入力してください')),
          );
          return;
        }

        if (startSec >= endSec) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('終了時刻は開始時刻より大きくしてください')),
          );
          return;
        }

        final item = PlaylistItem(
          videoId: video.videoId,
          startSec: startSec,
          endSec: endSec,
          videoTitle: videoTitle.isEmpty ? null : videoTitle,
          songTitle: songTitle.isEmpty ? null : songTitle,
        );

        await widget.playlistRepository.addPlaylistItem(item);
        await _loadPlaylist();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('プレイリストに追加しました')),
        );
      }
    } finally {
      if (kIsWeb) {
        _webPlayer.enablePointerEvents();
      }
    }
  }
}
