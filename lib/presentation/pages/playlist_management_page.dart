// lib/presentation/pages/playlist_management_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../platform/stubs/io_stub.dart' if (dart.library.io) 'dart:io'
    as io_platform;
import 'dart:html' as html show Blob, Url, AnchorElement;

import '../../../domain/entities/playlist_item.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../core/utils/csv_export.dart';

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

  /// 秒数を'00:00'形式（分:秒）の文字列に変換
  /// 例: 90 -> "01:30", 30 -> "00:30"
  String _formatTimeString(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPlaylist() async {
    final loadedPlaylist = await widget.playlistRepository.getPlaylist();
    setState(() {
      playlist = loadedPlaylist;
    });
  }

  Future<void> _showAddPlaylistItemDialog() async {
    final videoIdController = TextEditingController();
    final startSecController = TextEditingController();
    final endSecController = TextEditingController();
    final titleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('プレイリストに追加'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoIdController,
                decoration: InputDecoration(
                  labelText: '動画ID',
                  hintText: '例: dQw4w9WgXcQ',
                ),
                autofocus: true,
              ),
              SizedBox(height: 8),
              TextField(
                controller: startSecController,
                decoration: InputDecoration(
                  labelText: '開始時刻（分:秒）',
                  hintText: '例: 00:30',
                ),
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
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'タイトル（オプション）',
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
            child: Text('追加'),
          ),
        ],
      ),
    );

    if (result == true) {
      final videoId = videoIdController.text.trim();
      final startSecStr = startSecController.text.trim();
      final endSecStr = endSecController.text.trim();
      final title = titleController.text.trim();

      if (videoId.isEmpty || startSecStr.isEmpty || endSecStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('動画ID、開始時刻、終了時刻は必須です')),
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
        videoId: videoId,
        startSec: startSec,
        endSec: endSec,
        title: title.isEmpty ? null : title,
      );

      await widget.playlistRepository.addPlaylistItem(item);
      await _loadPlaylist();
    }
  }

  Future<void> _importPlaylistJson() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);
    if (res == null) return;

    String jsonStr;
    if (kIsWeb) {
      final bytes = res.files.first.bytes;
      if (bytes == null) return;
      jsonStr = utf8.decode(bytes);
    } else {
      final file = io_platform.File(res.files.first.path!);
      jsonStr = await file.readAsString();
    }

    try {
      final arr = jsonDecode(jsonStr) as List<dynamic>;
      final importedPlaylist = arr
          .map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      await widget.playlistRepository.savePlaylist(importedPlaylist);
      await _loadPlaylist();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プレイリストをインポートしました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSONファイルの読み込みに失敗しました: $e')),
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

    final sb = StringBuffer();
    sb.writeln('title,video_id,start_sec,end_sec,link');
    for (var item in playlist) {
      final link = 'https://youtu.be/${item.videoId}?t=${item.startSec}';
      sb.writeln(
          '${CsvExport.escape(item.title ?? '')},${item.videoId},${item.startSec},${item.endSec},$link');
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
                      onPressed: _importPlaylistJson,
                      tooltip: 'JSON取り込み',
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
                : ListView.builder(
                    itemCount: playlist.length,
                    itemBuilder: (context, idx) {
                      final item = playlist[idx];
                      return ListTile(
                        title: Text(item.title ?? '動画 ${item.videoId}'),
                        subtitle: Text(
                          '${item.videoId} @ ${_formatTimeString(item.startSec)} - ${_formatTimeString(item.endSec)}',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline),
                          onPressed: () async {
                            await widget.playlistRepository
                                .removePlaylistItem(idx);
                            await _loadPlaylist();
                          },
                          tooltip: '削除',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
