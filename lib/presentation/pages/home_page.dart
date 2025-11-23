// lib/presentation/pages/home_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../platform/stubs/io_stub.dart' if (dart.library.io) 'dart:io'
    as io_platform;
import '../../../platform/stubs/html_stub.dart'
    if (dart.library.html) 'dart:html' as html show Blob, Url, AnchorElement;

import '../../../domain/entities/video_item.dart';
import '../../../domain/entities/playlist_item.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_repository_impl.dart';
import '../../../platform/youtube_player/web_player.dart';
import '../../../platform/youtube_player/desktop_player.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/services/analytics_service.dart';
import '../widgets/youtube_list_download_dialog.dart';

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
  bool _audioOnlyMode = false;
  String? _appVersion;
  int _repeatMode = 0; // 0: なし, 1: 1曲リピート, 2: 全曲リピート
  bool _shuffleMode = false;
  List<int>? _shuffledIndices; // シャッフルされたインデックスの順序

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

    // バージョン情報を取得
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // バージョン情報の取得に失敗した場合は無視
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

    // アナリティクス: 動画選択
    AnalyticsService.logVideoSelected(videoId: v.videoId);

    if (kIsWeb) {
      _currentVideoId = v.videoId;
      setState(() {
        _isPlaying = false;
      });
    } else {
      _desktopPlayer.loadVideo(v.videoId);
    }
  }

  void _playTimeRange(String videoId, int? startSec, int? endSec) {
    if (kIsWeb) {
      _playTimeRangeWeb(videoId, startSec, endSec);
    } else {
      _playTimeRangeDesktop(videoId, startSec, endSec);
    }
  }

  void _playTimeRangeWeb(String videoId, int? startSec, int? endSec) {
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
            // 1曲リピートモードの場合は同じ曲を再度再生
            if (_repeatMode == 1) {
              final item = playlist[currentPlaylistIndex!];
              _playTimeRange(item.videoId, item.startSec, item.endSec);
            } else {
              _playNextPlaylistItem();
            }
          } else {
            setState(() {
              isPlayingPlaylist = false;
              currentPlaylistIndex = null;
            });
          }
        }
      },
      audioOnly: _audioOnlyMode,
    );
  }

  void _playTimeRangeDesktop(String videoId, int? startSec, int? endSec) {
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

    int nextIndex;
    if (_shuffleMode && _shuffledIndices != null) {
      // シャッフルモード: シャッフルされた順序を使用
      final currentShuffledPosition =
          _shuffledIndices!.indexOf(currentPlaylistIndex!);
      if (currentShuffledPosition == -1) {
        // 現在のインデックスがシャッフルリストにない場合（通常は発生しない）
        setState(() {
          isPlayingPlaylist = false;
          currentPlaylistIndex = null;
        });
        return;
      }

      final nextShuffledPosition = currentShuffledPosition + 1;
      if (nextShuffledPosition >= _shuffledIndices!.length) {
        // シャッフルリストの最後に到達した場合
        if (_repeatMode == 2) {
          // 全曲リピート: シャッフルを再生成して最初から
          _shufflePlaylist();
          setState(() {
            currentPlaylistIndex = _shuffledIndices![0];
          });
          final item = playlist[_shuffledIndices![0]];
          _playTimeRange(item.videoId, item.startSec, item.endSec);
        } else {
          // リピートなし: 停止
          setState(() {
            isPlayingPlaylist = false;
            currentPlaylistIndex = null;
          });
        }
        return;
      }
      nextIndex = _shuffledIndices![nextShuffledPosition];
    } else {
      // 通常モード: 順番通り
      nextIndex = currentPlaylistIndex! + 1;
      if (nextIndex >= playlist.length) {
        // プレイリストの最後に到達した場合
        if (_repeatMode == 2) {
          // 全曲リピート: 最初に戻る
          setState(() {
            currentPlaylistIndex = 0;
          });
          final item = playlist[0];
          _playTimeRange(item.videoId, item.startSec, item.endSec);
        } else {
          // リピートなし: 停止
          setState(() {
            isPlayingPlaylist = false;
            currentPlaylistIndex = null;
          });
        }
        return;
      }
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

    // アナリティクス: CSVエクスポート
    AnalyticsService.logCsvExported(itemCount: playlist.length);

    final sb = StringBuffer();
    sb.writeln('video_title,song_title,video_id,start_sec,end_sec,link');
    for (var item in playlist) {
      final link = item.startSec != null
          ? 'https://youtu.be/${item.videoId}?t=${item.startSec}'
          : 'https://youtu.be/${item.videoId}';
      sb.writeln(
          '${CsvExport.escape(item.videoTitle ?? '')},${CsvExport.escape(item.songTitle ?? '')},${item.videoId},${item.startSec ?? ''},${item.endSec ?? ''},$link');
    }

    if (kIsWeb) {
      final blob = html.Blob([sb.toString()], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'playlist_export.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('プレイリストファイルをダウンロードしました')));
    } else {
      final dir = await getApplicationSupportDirectory();
      final out = io_platform.File(
          '${dir.path}${io_platform.Platform.pathSeparator}playlist_export.csv');
      await out.writeAsString(sb.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exported to ${out.path}')));
    }
  }

  void _shufflePlaylist() {
    if (playlist.isEmpty) return;

    final indices = List.generate(playlist.length, (i) => i);
    indices.shuffle(Random());
    _shuffledIndices = indices;
  }

  void _playPlaylist() {
    if (playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プレイリストが空です')),
      );
      return;
    }

    // アナリティクス: プレイリスト再生
    AnalyticsService.logPlaylistPlayed(itemCount: playlist.length);

    // シャッフルモードが有効な場合、インデックスをシャッフル
    if (_shuffleMode) {
      _shufflePlaylist();
    } else {
      _shuffledIndices = null;
    }

    final startIndex =
        _shuffleMode && _shuffledIndices != null ? _shuffledIndices![0] : 0;

    setState(() {
      isPlayingPlaylist = true;
      currentPlaylistIndex = startIndex;
    });

    final item = playlist[startIndex];
    _playTimeRange(item.videoId, item.startSec, item.endSec);
  }

  void _stopPlaylist() {
    _timeUpdateTimer?.cancel();
    _webPlayer.pause();

    setState(() {
      _isPlaying = false;
      isPlayingPlaylist = false;
      currentPlaylistIndex = null;
      _shuffledIndices = null;
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
      // アナリティクス: 開発者モード有効化
      AnalyticsService.logDeveloperModeEnabled();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            // 画面幅が600px以下の場合、または縦向きの場合はスマートフォンモード（縦並び）
            final isMobile = constraints.maxWidth < 600 ||
                orientation == Orientation.portrait;

            final left = Container(
              width: isMobile ? double.infinity : 320,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (playlist.isNotEmpty) ...[
                                  IconButton(
                                    icon: Icon(
                                      isPlayingPlaylist
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: isPlayingPlaylist
                                        ? _stopPlaylist
                                        : _playPlaylist,
                                    tooltip: isPlayingPlaylist ? '停止' : '再生',
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(8),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _repeatMode == 0
                                          ? Icons.repeat
                                          : _repeatMode == 1
                                              ? Icons.repeat_one
                                              : Icons.repeat,
                                      color:
                                          _repeatMode > 0 ? Colors.blue : null,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _repeatMode = (_repeatMode + 1) % 3;
                                      });
                                    },
                                    tooltip: _repeatMode == 0
                                        ? 'リピートなし'
                                        : _repeatMode == 1
                                            ? '1曲リピート'
                                            : '全曲リピート',
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(8),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.shuffle,
                                      color: _shuffleMode ? Colors.blue : null,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _shuffleMode = !_shuffleMode;
                                        if (!_shuffleMode) {
                                          _shuffledIndices = null;
                                        }
                                      });
                                    },
                                    tooltip: _shuffleMode
                                        ? 'シャッフル再生: オン'
                                        : 'シャッフル再生: オフ',
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(8),
                                  ),
                                  if (isPlayingPlaylist &&
                                      currentPlaylistIndex != null)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text(
                                        _shuffleMode && _shuffledIndices != null
                                            ? '${_shuffledIndices!.indexOf(currentPlaylistIndex!) + 1} / ${playlist.length} (シャッフル)'
                                            : '${currentPlaylistIndex! + 1} / ${playlist.length}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: () async {
                            await Navigator.pushNamed(
                                context, '/playlist-management');
                            await _loadPlaylist();
                          },
                          tooltip: 'プレイリスト管理',
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.all(8),
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
                          final displayTitle = item.songTitle ??
                              item.videoTitle ??
                              '動画 ${item.videoId}';
                          final subtitleParts = <String>[];
                          if (item.videoTitle != null &&
                              item.videoTitle != item.songTitle) {
                            subtitleParts.add('動画: ${item.videoTitle}');
                          }
                          final timeRangeStr = item.startSec != null &&
                                  item.endSec != null
                              ? '${TimeFormat.formatTimeString(item.startSec!)} - ${TimeFormat.formatTimeString(item.endSec!)}'
                              : item.startSec != null
                                  ? '${TimeFormat.formatTimeString(item.startSec!)} - 最後まで'
                                  : item.endSec != null
                                      ? '最初から - ${TimeFormat.formatTimeString(item.endSec!)}'
                                      : '最初から最後まで';
                          subtitleParts.add('${item.videoId} @ $timeRangeStr');
                          return ListTile(
                            title: Text(
                              displayTitle,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent ? Colors.blue : null,
                              ),
                            ),
                            subtitle: Text(subtitleParts.join('\n')),
                            trailing: IconButton(
                              icon: Icon(
                                isCurrent ? Icons.equalizer : Icons.play_arrow,
                                size: 20,
                              ),
                              onPressed: () {
                                // シャッフルモードが有効な場合、新しいシャッフル順序を生成
                                if (_shuffleMode) {
                                  _shufflePlaylist();
                                }
                                setState(() {
                                  isPlayingPlaylist = true;
                                  currentPlaylistIndex = idx;
                                });
                                _playTimeRange(
                                    item.videoId, item.startSec, item.endSec);
                              },
                              tooltip: isCurrent ? '再生中' : '再生',
                            ),
                            onTap: () {
                              // シャッフルモードが有効な場合、新しいシャッフル順序を生成
                              if (_shuffleMode) {
                                _shufflePlaylist();
                              }
                              setState(() {
                                isPlayingPlaylist = true;
                                currentPlaylistIndex = idx;
                              });
                              _playTimeRange(
                                  item.videoId, item.startSec, item.endSec);
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
                    height: isMobile ? 150 : 200,
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
                                  onPressed: () =>
                                      _showCreatePlaylistItemDialog(video),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            'Uta(Gawa)Picker',
                          );
                        },
                      ),
                      if (_isDeveloperModeEnabled && _appVersion != null)
                        Text(
                          'v$_appVersion',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.normal),
                        ),
                    ],
                  ),
                ),
                actions: [
                  // 音声のみモード切り替えボタン（Web + 開発者モードのみ）
                  if (kIsWeb && _isDeveloperModeEnabled)
                    IconButton(
                      icon: Icon(
                        _audioOnlyMode ? Icons.audiotrack : Icons.video_library,
                        color: _audioOnlyMode ? Colors.blue : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _audioOnlyMode = !_audioOnlyMode;
                        });
                        // アナリティクス: 音声のみモード切り替え
                        AnalyticsService.logAudioOnlyModeToggled(
                            enabled: _audioOnlyMode);
                        // 再生中の場合は再作成
                        if (_isPlaying && _currentVideoId != null) {
                          // 現在の再生位置を取得して再作成
                          final currentItem =
                              isPlayingPlaylist && currentPlaylistIndex != null
                                  ? playlist[currentPlaylistIndex!]
                                  : null;
                          if (currentItem != null) {
                            _playTimeRange(currentItem.videoId,
                                currentItem.startSec, currentItem.endSec);
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _audioOnlyMode
                                  ? '音声重視モード（低解像度）を有効にしました'
                                  : '通常モードに戻しました',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: _audioOnlyMode
                          ? '音声重視モード（低解像度）: オフ'
                          : '音声重視モード（低解像度）: オン',
                    ),
                  if (_isDeveloperModeEnabled)
                    IconButton(
                      icon: Icon(Icons.file_upload),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/playlist-import');
                        await _loadPlaylist();
                      },
                      tooltip: 'JSONからプレイリストを作成',
                    ),
                  if (_isDeveloperModeEnabled)
                    IconButton(
                      icon: Icon(Icons.download),
                      onPressed: _showYoutubeListDownloadDialog,
                      tooltip: 'YouTubeリストからCSVをダウンロード',
                    ),
                ],
              ),
              body: isMobile
                  ? Column(
                      children: [
                        // スマートフォン: 動画プレーヤーを上に、プレイリストを下に
                        Expanded(child: right),
                        Container(
                          height: constraints.maxHeight * 0.4,
                          child: left,
                        ),
                      ],
                    )
                  : Row(children: [left, Expanded(child: right)]),
            );
          },
        );
      },
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
                    labelText: '開始時刻（分:秒 または 時:分:秒）',
                    hintText: '例: 00:30 または 01:07:52',
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: endSecController,
                  decoration: InputDecoration(
                    labelText: '終了時刻（分:秒 または 時:分:秒）',
                    hintText: '例: 01:30 または 01:10:00',
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

        final startSec = TimeFormat.parseTimeString(startSecStr);
        final endSec = TimeFormat.parseTimeString(endSecStr);

        if (startSec == null || endSec == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '開始時刻と終了時刻は「分:秒」（例: 00:30）または「時:分:秒」（例: 01:07:52）形式で入力してください')),
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
        // アナリティクス: プレイリストアイテム追加
        AnalyticsService.logPlaylistItemAdded(
          videoId: item.videoId,
          startSec: item.startSec,
          endSec: item.endSec,
        );
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

  /// YouTubeリストIDを指定してCSVをダウンロードするダイアログを表示
  Future<void> _showYoutubeListDownloadDialog() async {
    await showYoutubeListDownloadDialog(
      context,
      onDownload: (playlistId) =>
          downloadCsvFromYoutubeList(context, playlistId),
      onDisablePointerEvents: kIsWeb ? _webPlayer.disablePointerEvents : null,
      onEnablePointerEvents: kIsWeb ? _webPlayer.enablePointerEvents : null,
    );
  }
}
