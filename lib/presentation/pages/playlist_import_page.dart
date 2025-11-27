// lib/presentation/pages/playlist_import_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../../../platform/stubs/io_stub.dart' if (dart.library.io) 'dart:io'
    as io_platform;

import '../../../domain/entities/video_item.dart';
import '../../../domain/entities/playlist_item.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/time_format.dart';

class PlaylistImportPage extends StatefulWidget {
  final PlaylistRepository playlistRepository;

  const PlaylistImportPage({
    super.key,
    required this.playlistRepository,
  });

  @override
  State<PlaylistImportPage> createState() => _PlaylistImportPageState();
}

class _PlaylistImportPageState extends State<PlaylistImportPage> {
  List<VideoItem> videos = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JSONからプレイリストを作成'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '動画リスト',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.file_upload),
                  label: Text('JSONファイルを選択'),
                  onPressed: isLoading ? null : _importJsonFile,
                ),
              ],
            ),
          ),
          if (videos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'JSONファイルを選択して動画リストを読み込みます',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '動画数: ${videos.length}',
                          style: TextStyle(fontSize: 14),
                        ),
                        ElevatedButton(
                          onPressed: _clearList,
                          child: Text('リストをクリア'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: videos.length,
                      itemBuilder: (context, idx) {
                        final video = videos[idx];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${idx + 1}'),
                          ),
                          title: Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('ID: ${video.videoId}'),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                _showCreatePlaylistItemDialog(video),
                            tooltip: 'プレイリストに追加',
                          ),
                          onTap: () => _showCreatePlaylistItemDialog(video),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _importJsonFile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final res = await FilePicker.platform
          .pickFiles(type: FileType.any, allowMultiple: false);
      if (res == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      String jsonStr;
      if (kIsWeb) {
        final bytes = res.files.first.bytes;
        if (bytes == null) {
          setState(() {
            isLoading = false;
          });
          return;
        }
        jsonStr = utf8.decode(bytes);
      } else {
        final file = io_platform.File(res.files.first.path!);
        jsonStr = await file.readAsString();
      }

      final arr = jsonDecode(jsonStr) as List<dynamic>;
      setState(() {
        videos = arr
            .map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
            .toList();
        isLoading = false;
      });

      // アナリティクス: JSONインポート
      AnalyticsService.logJsonImported(videoCount: videos.length);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${videos.length}件の動画を読み込みました')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSONファイルの読み込みに失敗しました: $e')),
      );
    }
  }

  void _clearList() {
    setState(() {
      videos = [];
    });
  }

  /// 動画からプレイリストアイテムを作成するダイアログを表示
  Future<void> _showCreatePlaylistItemDialog(VideoItem video) async {
    final startSecController = TextEditingController();
    final endSecController = TextEditingController();
    final videoTitleController = TextEditingController(text: video.title);
    final songTitleController = TextEditingController();

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
                  labelText: '開始時刻（オプション、分:秒 または 時:分:秒）',
                  hintText: '例: 00:30 または 01:07:52（空欄の場合は動画の最初から）',
                ),
                autofocus: true,
              ),
              SizedBox(height: 8),
              TextField(
                controller: endSecController,
                decoration: InputDecoration(
                  labelText: '終了時刻（オプション、分:秒 または 時:分:秒）',
                  hintText: '例: 01:30 または 01:10:00（空欄の場合は動画の最後まで）',
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

      int? startSec;
      int? endSec;

      // 開始時刻の解析（空欄の場合はnull）
      if (startSecStr.isNotEmpty) {
        startSec = TimeFormat.parseTimeString(startSecStr);
        if (startSec == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '開始時刻は「分:秒」（例: 00:30）または「時:分:秒」（例: 01:07:52）形式で入力してください')),
          );
          return;
        }
      }

      // 終了時刻の解析（空欄の場合はnull）
      if (endSecStr.isNotEmpty) {
        endSec = TimeFormat.parseTimeString(endSecStr);
        if (endSec == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '終了時刻は「分:秒」（例: 01:30）または「時:分:秒」（例: 01:10:00）形式で入力してください')),
          );
          return;
        }
      }

      // 両方指定されている場合は、開始時刻 < 終了時刻をチェック
      if (startSec != null && endSec != null && startSec >= endSec) {
        if (!mounted) return;
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
      // アナリティクス: プレイリストアイテム追加（インポートページから）
      AnalyticsService.logPlaylistItemAdded(
        videoId: item.videoId,
        startSec: item.startSec,
        endSec: item.endSec,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プレイリストに追加しました')),
      );
    }
  }
}
