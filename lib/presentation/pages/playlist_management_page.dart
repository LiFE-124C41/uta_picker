// lib/presentation/pages/playlist_management_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../platform/stubs/io_stub.dart' if (dart.library.io) 'dart:io'
    as io_platform;
import '../../../platform/stubs/html_stub.dart'
    if (dart.library.html) 'dart:html' as html show Blob, Url, AnchorElement;

import '../../../domain/entities/playlist_item.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/utils/csv_import.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/utils/youtube_url_parser.dart';
import '../../../core/services/analytics_service.dart';

class PlaylistManagementPage extends StatefulWidget {
  final PlaylistRepository playlistRepository;

  const PlaylistManagementPage({
    Key? key,
    required this.playlistRepository,
  }) : super(key: key);

  @override
  State<PlaylistManagementPage> createState() => _PlaylistManagementPageState();
}

class _PlaylistManagementPageState extends State<PlaylistManagementPage> {
  List<PlaylistItem> playlist = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final loadedPlaylist = await widget.playlistRepository.getPlaylist();
    setState(() {
      playlist = loadedPlaylist;
    });
  }

  Future<void> _showAddPlaylistItemDialog() async {
    await _showPlaylistItemDialog();
  }

  Future<void> _showEditPlaylistItemDialog(int index) async {
    final item = playlist[index];
    await _showPlaylistItemDialog(
      index: index,
      initialVideoId: item.videoId,
      initialStartSec: item.startSec,
      initialEndSec: item.endSec,
      initialVideoTitle: item.videoTitle,
      initialSongTitle: item.songTitle,
    );
  }

  Future<void> _showPlaylistItemDialog({
    int? index,
    String? initialVideoId,
    int? initialStartSec,
    int? initialEndSec,
    String? initialVideoTitle,
    String? initialSongTitle,
  }) async {
    final videoIdController = TextEditingController(text: initialVideoId ?? '');
    final startSecController = TextEditingController(
        text: initialStartSec != null
            ? TimeFormat.formatTimeString(initialStartSec)
            : '');
    final endSecController = TextEditingController(
        text: initialEndSec != null
            ? TimeFormat.formatTimeString(initialEndSec)
            : '');
    final videoTitleController =
        TextEditingController(text: initialVideoTitle ?? '');
    final songTitleController =
        TextEditingController(text: initialSongTitle ?? '');

    final isEdit = index != null;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'プレイリスト項目を編集' : 'プレイリストに追加'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoIdController,
                decoration: InputDecoration(
                  labelText: '動画IDまたはURL',
                  hintText: '例: dQw4w9WgXcQ または 動画URL',
                ),
                autofocus: true,
              ),
              SizedBox(height: 8),
              TextField(
                controller: startSecController,
                decoration: InputDecoration(
                  labelText: '開始時刻（分:秒 または 時:分:秒）',
                  hintText: '例: 00:30 または 01:07:52',
                ),
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
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEdit ? '更新' : '追加'),
          ),
        ],
      ),
    );

    if (result == true) {
      final videoIdInput = videoIdController.text.trim();
      final startSecStr = startSecController.text.trim();
      final endSecStr = endSecController.text.trim();
      final videoTitle = videoTitleController.text.trim();
      final songTitle = songTitleController.text.trim();

      if (videoIdInput.isEmpty || startSecStr.isEmpty || endSecStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('動画ID、開始時刻、終了時刻は必須です')),
        );
        return;
      }

      // YouTubeのURLからvideoIdを抽出
      final videoId = YoutubeUrlParser.extractVideoId(videoIdInput);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('有効な動画IDまたはYouTubeのURLを入力してください')),
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
        videoId: videoId,
        startSec: startSec,
        endSec: endSec,
        videoTitle: videoTitle.isEmpty ? null : videoTitle,
        songTitle: songTitle.isEmpty ? null : songTitle,
      );

      if (isEdit) {
        await widget.playlistRepository.updatePlaylistItem(index, item);
      } else {
        await widget.playlistRepository.addPlaylistItem(item);
        // アナリティクス: プレイリストアイテム追加（管理画面から）
        AnalyticsService.logPlaylistItemAdded(
          videoId: item.videoId,
          startSec: item.startSec,
          endSec: item.endSec,
        );
      }
      await _loadPlaylist();
    }
  }

  Future<void> _importPlaylistCsv() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);
    if (res == null) return;

    String csvStr;
    if (kIsWeb) {
      final bytes = res.files.first.bytes;
      if (bytes == null) return;
      csvStr = utf8.decode(bytes);
    } else {
      final file = io_platform.File(res.files.first.path!);
      csvStr = await file.readAsString();
    }

    try {
      final rows = CsvImport.parseCsv(csvStr);
      final importedPlaylist = <PlaylistItem>[];

      for (final row in rows) {
        final videoIdInput = row['video_id'] ?? '';
        final startSecStr = row['start_sec'] ?? '';
        final endSecStr = row['end_sec'] ?? '';
        final videoTitle =
            row['video_title']?.isEmpty == true ? null : row['video_title'];
        final songTitle =
            row['song_title']?.isEmpty == true ? null : row['song_title'];

        if (videoIdInput.isEmpty || startSecStr.isEmpty || endSecStr.isEmpty) {
          continue; // 必須フィールドが空の行はスキップ
        }

        // YouTubeのURLからvideoIdを抽出
        final videoId = YoutubeUrlParser.extractVideoId(videoIdInput);
        if (videoId == null) {
          continue; // 有効なvideoIdが抽出できない行はスキップ
        }

        final startSec = int.tryParse(startSecStr);
        final endSec = int.tryParse(endSecStr);

        if (startSec == null || endSec == null) {
          continue; // 数値に変換できない行はスキップ
        }

        if (startSec >= endSec) {
          continue; // 開始時刻が終了時刻以上の行はスキップ
        }

        importedPlaylist.add(PlaylistItem(
          videoId: videoId,
          startSec: startSec,
          endSec: endSec,
          videoTitle: videoTitle,
          songTitle: songTitle,
        ));
      }

      if (importedPlaylist.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('有効なプレイリスト項目が見つかりませんでした')),
        );
        return;
      }

      await widget.playlistRepository.savePlaylist(importedPlaylist);
      await _loadPlaylist();
      // アナリティクス: CSVインポート
      AnalyticsService.logCsvImported(itemCount: importedPlaylist.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${importedPlaylist.length}件のプレイリスト項目をインポートしました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSVファイルの読み込みに失敗しました: $e')),
      );
    }
  }

  Future<void> _exportPlaylistCsv() async {
    if (playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プレイリストが空です')),
      );
      return;
    }

    // アナリティクス: CSVエクスポート（管理画面から）
    AnalyticsService.logCsvExported(itemCount: playlist.length);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プレイリスト管理'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('プレイリスト', style: TextStyle(fontSize: 18)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _showAddPlaylistItemDialog,
                      tooltip: '追加',
                    ),
                    IconButton(
                      icon: Icon(Icons.file_upload),
                      onPressed: _importPlaylistCsv,
                      tooltip: 'CSV取り込み',
                    ),
                    IconButton(
                      icon: Icon(Icons.file_download),
                      onPressed: _exportPlaylistCsv,
                      tooltip: 'CSVエクスポート',
                    ),
                    if (playlist.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () async {
                          await widget.playlistRepository.clearPlaylist();
                          await _loadPlaylist();
                        },
                        tooltip: '全削除',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: playlist.isEmpty
                ? Center(
                    child: Text('プレイリストが空です\n「+」ボタンで追加してください'),
                  )
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) async {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = playlist.removeAt(oldIndex);
                      playlist.insert(newIndex, item);
                      await widget.playlistRepository.savePlaylist(playlist);
                      setState(() {});
                    },
                    children: playlist.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final displayTitle = item.songTitle ??
                          item.videoTitle ??
                          '動画 ${item.videoId}';
                      final subtitleParts = <String>[];
                      if (item.videoTitle != null &&
                          item.videoTitle != item.songTitle) {
                        subtitleParts.add('動画: ${item.videoTitle}');
                      }
                      subtitleParts.add(
                          '${item.videoId} @ ${TimeFormat.formatTimeString(item.startSec)} - ${TimeFormat.formatTimeString(item.endSec)}');
                      return ListTile(
                        key: ObjectKey(item),
                        title: Text(displayTitle),
                        subtitle: Text(subtitleParts.join('\n')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined),
                              onPressed: () => _showEditPlaylistItemDialog(idx),
                              tooltip: '編集',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              onPressed: () async {
                                await widget.playlistRepository
                                    .removePlaylistItem(idx);
                                await _loadPlaylist();
                              },
                              tooltip: '削除',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
