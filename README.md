# uta_picker

YouTubeアーカイブ動画から曲の開始時間と終了時間をマークするためのFlutterアプリケーションです。

## 概要

このアプリケーションは、YouTubeのアーカイブ動画（ライブ配信の録画など）を視聴しながら、動画内の各曲の開始時間と終了時間を記録し、データベースに保存することができます。記録したデータはCSV形式でエクスポートできます。

## デプロイ

このアプリケーションのWeb版は以下のURLで公開されています：

🔗 **https://life-124c41.github.io/uta_picker/**

## 主な機能

- **動画リストのインポート**: JSONファイルからYouTube動画のリストをインポート
- **動画再生**: WebViewを使用してYouTube動画をアプリ内で再生
- **時間記録**: 曲の開始時間と終了時間を記録
- **データベース保存**: SQLiteデータベースに記録を保存
- **CSVエクスポート**: 記録したデータをCSV形式でエクスポート
- **タイムスタンプリンク**: 記録した時間のYouTubeリンクを生成・コピー

## 必要な環境

- Flutter SDK 3.0.0以上
- Dart SDK 3.0.0以上
- 対応プラットフォーム: Windows, macOS, Linux, Android, iOS, Web

## インストール

1. リポジトリをクローンします：

```bash
git clone <repository-url>
cd uta_picker
```

2. 依存パッケージをインストールします：

```bash
flutter pub get
```

## 使用方法

### 1. 動画リストの準備

まず、`script/fetch_videos.py`を使用してYouTubeチャンネルの動画情報を取得します。詳細は[script/README.md](script/README.md)を参照してください。

```bash
cd script
python fetch_videos.py YOUR_API_KEY CHANNEL_ID
```

これにより`videos.json`ファイルが生成されます。

### 2. アプリの起動

```bash
flutter run
```

### 3. 動画リストのインポート

1. アプリ起動後、「Import videos.json」ボタンをクリック
2. `videos.json`ファイルを選択
3. 左側のリストに動画が表示されます

### 4. 動画の選択と再生

1. 左側のリストから動画を選択
2. 右側のWebViewで動画が再生されます

### 5. 曲の時間を記録

1. **開始時間の記録**:
   - 動画を再生し、曲の開始位置に移動
   - 「Start」ボタンをクリック
   - 曲名を入力して保存

2. **終了時間の記録**:
   - 曲の終了位置に移動
   - 「End」ボタンをクリック
   - 最新の未完了レコードに終了時間が記録されます

### 6. データのエクスポート

「Export CSV」ボタンをクリックすると、記録したデータがCSV形式でエクスポートされます。ファイルはアプリケーションのサポートディレクトリに保存されます。

## その他の機能

- **Seek (manually)**: 指定した秒数に移動
- **Copy link**: 現在の再生位置のYouTubeリンクをクリップボードにコピー
- **Refresh**: データベースから最新の記録を再読み込み
- **Reload DB**: データベースを再読み込み

## データベース構造

アプリケーションはSQLiteデータベースを使用して、以下の情報を保存します：

- `id`: レコードID（自動採番）
- `video_id`: YouTube動画ID
- `video_title`: 動画タイトル
- `start_sec`: 開始時間（秒）
- `end_sec`: 終了時間（秒、オプション）
- `song_title`: 曲名
- `recorded_at`: 記録日時
- `note`: メモ（オプション）

データベースファイルは、アプリケーションのサポートディレクトリに`song_picker.db`として保存されます。

## エクスポート形式

CSVファイルには以下の列が含まれます：

- `song_title`: 曲名
- `video_title`: 動画タイトル
- `video_id`: YouTube動画ID
- `start_sec`: 開始時間（秒）
- `end_sec`: 終了時間（秒）
- `link`: YouTubeタイムスタンプリンク

## プロジェクト構造

```
uta_picker/
├── lib/
│   └── main.dart          # メインアプリケーションコード
├── script/
│   ├── fetch_videos.py    # YouTube動画情報取得スクリプト
│   └── README.md          # スクリプトの使用方法
├── assets/
│   └── videos.json        # 動画リスト（例）
├── pubspec.yaml           # Flutterプロジェクト設定
└── README.md              # このファイル
```

## 依存パッケージ

- `webview_flutter`: YouTube動画の再生
- `file_picker`: JSONファイルの選択
- `path_provider`: アプリケーションディレクトリへのアクセス
- `sqflite_common_ffi`: デスクトップ向けSQLiteデータベース
- `intl`: 日時フォーマット
- `url_launcher`: 外部ブラウザでのリンク開く

## ライセンス

このプロジェクトのライセンスについては、[LICENSE](LICENSE)ファイルを参照してください。

## GitHub Pagesへのデプロイ

このアプリのWeb版をGitHub Pagesにデプロイする手順：

### 1. GitHub Pagesの設定

1. GitHubリポジトリの「Settings」→「Pages」に移動
2. 「Source」で「GitHub Actions」を選択

### 2. ワークフローの確認

`.github/workflows/deploy.yml`ファイルが作成されています。このファイルの以下の点を確認してください：

- `branches`セクションで、お使いのメインブランチ名（`main`または`master`）が指定されているか
- `base-href`がリポジトリ名と一致しているか（デフォルトは`/uta_picker/`）

リポジトリ名が異なる場合は、`.github/workflows/deploy.yml`の以下の行を修正してください：

```yaml
run: flutter build web --base-href "/uta_picker/" --release
```

`/uta_picker/`の部分を`/あなたのリポジトリ名/`に変更してください。

### 3. デプロイの実行

1. メインブランチにプッシュすると、自動的にデプロイが開始されます
2. または、「Actions」タブから手動でワークフローを実行することもできます
3. デプロイが完了すると、`https://あなたのユーザー名.github.io/uta_picker/`でアクセスできます

### 4. ローカルでの確認

ローカルでビルドして確認する場合：

```bash
flutter build web --base-href "/uta_picker/" --release
cd build/web
# ローカルサーバーで確認（例：Python）
python -m http.server 8000
```

## 注意事項

- YouTube Data APIを使用する場合は、APIキーの使用制限に注意してください
- データベースファイルは定期的にバックアップすることを推奨します
- WebViewを使用するため、インターネット接続が必要です
- GitHub Pagesにデプロイする場合、Web版では一部の機能（ファイルシステムへのアクセスなど）が制限される可能性があります
