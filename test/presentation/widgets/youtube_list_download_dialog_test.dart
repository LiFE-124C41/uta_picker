import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uta_picker/presentation/widgets/youtube_list_download_dialog.dart';

void main() {
  group('showYoutubeListDownloadDialog', () {
    testWidgets('ダイアログが正しく表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showYoutubeListDownloadDialog(
                      context,
                      onDownload: (id) async {},
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 要素の確認
      expect(find.text('YouTubeリストからプレイリストをダウンロード'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('ダウンロード'), findsOneWidget);
      expect(find.text('YouTubeリストID'), findsOneWidget);
    });

    testWidgets('空入力でダウンロードボタンを押すとSnackBarが表示されること',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showYoutubeListDownloadDialog(
                      context,
                      onDownload: (id) async {},
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 空のままダウンロードボタンを押下
      await tester.tap(find.text('ダウンロード'));
      await tester.pumpAndSettle(); // ダイアログが閉じ、SnackBarが表示されるまで待機

      // SnackBarの確認
      expect(find.text('YouTubeリストIDを入力してください'), findsOneWidget);

      // ダイアログが閉じていることを確認
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('入力ありでダウンロードボタンを押すとコールバックが呼ばれること', (WidgetTester tester) async {
      String? downloadedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showYoutubeListDownloadDialog(
                      context,
                      onDownload: (id) async {
                        downloadedId = id;
                      },
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // テキスト入力
      const testId = 'PL1234567890';
      await tester.enterText(find.byType(TextField), testId);
      await tester.pump();

      // ダウンロードボタン押下
      await tester.tap(find.text('ダウンロード'));
      await tester.pumpAndSettle();

      // コールバックの確認
      expect(downloadedId, testId);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('キャンセルボタンでダイアログが閉じ、コールバックが呼ばれないこと',
        (WidgetTester tester) async {
      bool isCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showYoutubeListDownloadDialog(
                      context,
                      onDownload: (id) async {
                        isCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // キャンセルボタン押下
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // 確認
      expect(isCalled, false);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
