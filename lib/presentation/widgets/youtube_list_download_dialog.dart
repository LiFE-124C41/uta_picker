// lib/presentation/widgets/youtube_list_download_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../platform/stubs/io_stub.dart' if (dart.library.io) 'dart:io'
    as io_platform;
import '../../../platform/stubs/html_stub.dart'
    if (dart.library.html) 'dart:html' as html show Blob, Url, AnchorElement;
import '../../../core/config/api_config.dart';

/// YouTubeリストからCSVをダウンロードするダイアログを表示
///
/// [onDownload] は、playlistIdを受け取り、ダウンロード処理を実行するコールバック
/// [onDisablePointerEvents] は、Web版でポインターイベントを無効化するコールバック（オプション）
/// [onEnablePointerEvents] は、Web版でポインターイベントを有効化するコールバック（オプション）
Future<void> showYoutubeListDownloadDialog(
  BuildContext context, {
  required Future<void> Function(String playlistId) onDownload,
  VoidCallback? onDisablePointerEvents,
  VoidCallback? onEnablePointerEvents,
}) async {
  final playlistIdController = TextEditingController();

  if (kIsWeb && onDisablePointerEvents != null) {
    onDisablePointerEvents();
  }
  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('YouTubeリストからCSVをダウンロード'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: playlistIdController,
                decoration: InputDecoration(
                  labelText: 'YouTubeリストID',
                  hintText: '例: PLxxxxxxxxxxxxxxxxxxxxx',
                  helperText: 'YouTubeプレイリストのIDを入力してください',
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (kIsWeb && onEnablePointerEvents != null) {
                onEnablePointerEvents();
              }
              Navigator.pop(context, false);
            },
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (kIsWeb && onEnablePointerEvents != null) {
                onEnablePointerEvents();
              }
              Navigator.pop(context, true);
            },
            child: Text('ダウンロード'),
          ),
        ],
      ),
    );

    if (result == true) {
      final playlistId = playlistIdController.text.trim();

      if (playlistId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('YouTubeリストIDを入力してください')),
        );
        return;
      }

      await onDownload(playlistId);
    }
  } finally {
    if (kIsWeb && onEnablePointerEvents != null) {
      onEnablePointerEvents();
    }
  }
}

/// YouTubeリストIDを指定してPOSTリクエストを送信し、CSVをダウンロード
Future<void> downloadCsvFromYoutubeList(
  BuildContext context,
  String playlistId,
) async {
  final endpoint = ApiConfig.endpoint;
  try {
    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    // POSTリクエストを送信（playlist_idはURLパラメータで渡す）
    final uri = Uri.parse(endpoint).replace(
      queryParameters: {
        'playlist_id': playlistId,
      },
    );

    if (kDebugMode) {
      print('POSTリクエスト送信: $uri');
    }

    // リクエストヘッダーを設定（CORS対応）
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'text/csv, application/json',
    };

    final response = await http
        .post(
      uri,
      headers: headers,
    )
        .timeout(
      Duration(seconds: 90),
      onTimeout: () {
        throw TimeoutException('リクエストがタイムアウトしました');
      },
    );

    // ローディングを閉じる
    Navigator.pop(context);

    if (response.statusCode == 200) {
      final csvContent = response.body;

      if (kIsWeb) {
        // Web版: Blobを使用してダウンロード
        final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'youtube_list_${playlistId}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSVファイルをダウンロードしました')),
        );
      } else {
        // デスクトップ版: ファイルに保存
        final dir = await getApplicationSupportDirectory();
        final file = io_platform.File(
            '${dir.path}${io_platform.Platform.pathSeparator}youtube_list_${playlistId}.csv');
        await file.writeAsString(csvContent);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSVファイルを保存しました: ${file.path}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'エラーが発生しました: ${response.statusCode} ${response.reasonPhrase}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } on TimeoutException catch (e) {
    Navigator.pop(context); // ローディングを閉じる
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('タイムアウト: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
  } on http.ClientException catch (e) {
    Navigator.pop(context); // ローディングを閉じる
    if (kDebugMode) {
      print('ClientException: $e');
    }
    String errorMessage = 'ネットワークエラーが発生しました';
    if (kIsWeb) {
      errorMessage += '\nCORSエラーの可能性があります。サーバー側のCORS設定を確認してください。';
    }
    errorMessage += '\n${e.message}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 8),
      ),
    );
  } catch (e, stackTrace) {
    Navigator.pop(context); // ローディングを閉じる
    if (kDebugMode) {
      print('エラー詳細: $e');
      print('スタックトレース: $stackTrace');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('エラーが発生しました: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
