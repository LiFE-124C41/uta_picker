# uta_picker

YouTubeアーカイブ動画から曲の開始時間と終了時間をマークするためのFlutterアプリケーションです。

## 概要

このアプリケーションは、YouTubeのアーカイブ動画（ライブ配信の録画など）から、動画内の各曲の開始時間と終了時間を指定してプレイリストを作成し、保存することができます。作成したプレイリストは連続再生でき、CSV形式でエクスポート・インポートも可能です。

## デプロイ

このアプリケーションのWeb版は以下のURLで公開されています：

🔗 **https://life-124c41.github.io/uta_picker/**

## 主な機能

- **動画再生**: iframeを使用してYouTube動画をアプリ内で再生
- **プレイリスト作成**: 動画の開始時間と終了時間を指定してプレイリストアイテムを作成
- **プレイリスト再生**: 作成したプレイリストを連続再生
- **データ保存**: SharedPreferencesにプレイリストを保存
- **CSVエクスポート/インポート**: プレイリストをCSV形式でエクスポート・インポート
- **プレイリスト管理**: プレイリストアイテムの追加、編集、削除、並び替え

## 必要な環境

- Flutter SDK 3.0.0以上
- Dart SDK 3.0.0以上
- 対応プラットフォーム: Web

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

まず、`script/fetch_videos.py`を使用してYouTubeプレイリストの動画情報を取得します。詳細は[script/README.md](script/README.md)を参照してください。

```bash
cd script
python fetch_videos.py YOUR_API_KEY PLAYLIST_ID
```

これにより`videos.json`ファイルが生成されます。

### 2. アプリの起動

```bash
flutter run
```

### 3. 動画リストのインポート（開発者モード）

1. アプリ起動後、タイトル「UtaPicker」を5回タップして開発者モードを有効化
2. 右上の「JSONからプレイリストを作成」ボタン（📤アイコン）をクリック
3. `videos.json`ファイルを選択
4. 動画リストが表示されます

### 4. プレイリストへの追加

1. **動画リストから追加**:
   - 動画リストから動画を選択
   - 「プレイリストに追加」ボタン（➕アイコン）をクリック
   - 開始時刻と終了時刻を「分:秒」または「時:分:秒」形式で入力（例: `00:30` または `01:07:52`）
   - 動画タイトルと楽曲タイトルを入力（オプション）
   - 「追加」をクリック

2. **プレイリスト管理画面から追加**:
   - 右上の「プレイリスト管理」ボタン（⚙️アイコン）をクリック
   - 「+」ボタンをクリック
   - 動画ID、開始時刻、終了時刻を入力
   - 「追加」をクリック

### 5. プレイリストの再生

1. 左側のプレイリストからアイテムを選択して再生
2. または、プレイリストの「再生」ボタン（▶️アイコン）をクリックして連続再生
3. 連続再生中は「停止」ボタン（⏹️アイコン）で停止できます

### 6. プレイリストの管理

1. 右上の「プレイリスト管理」ボタン（⚙️アイコン）をクリック
2. プレイリストアイテムの編集、削除、並び替えが可能
3. CSVのインポート/エクスポートもここから実行できます

## その他の機能

- **プレイリスト管理**: アイテムの追加、編集、削除、並び替え
- **CSVインポート**: CSVファイルからプレイリストを一括インポート
- **CSVエクスポート**: プレイリストをCSV形式でエクスポート
- **音声重視モード**（開発者モードのみ）: 低解像度で音声を重視した再生モード

## データ保存形式

アプリケーションはSharedPreferencesを使用してプレイリストを保存します。各プレイリストアイテムには以下の情報が含まれます：

- `video_id`: YouTube動画ID
- `start_sec`: 開始時間（秒）
- `end_sec`: 終了時間（秒）
- `video_title`: 動画タイトル（オプション）
- `song_title`: 楽曲タイトル（オプション）

## エクスポート形式

CSVファイルには以下の列が含まれます：

- `video_title`: 動画タイトル
- `song_title`: 楽曲タイトル
- `video_id`: YouTube動画ID
- `start_sec`: 開始時間（秒）
- `end_sec`: 終了時間（秒）
- `link`: YouTubeタイムスタンプリンク（`https://youtu.be/{video_id}?t={start_sec}`形式）

CSVインポート時は、同じ形式のCSVファイルを読み込むことができます。

## プロジェクト構造

```
uta_picker/
├── lib/
│   ├── main.dart                    # アプリケーションエントリーポイント
│   ├── presentation/                # UI層
│   │   ├── app.dart                 # アプリケーションルート
│   │   └── pages/                   # ページコンポーネント
│   │       ├── home_page.dart       # ホームページ
│   │       ├── playlist_management_page.dart  # プレイリスト管理ページ
│   │       └── playlist_import_page.dart       # JSONインポートページ
│   ├── domain/                      # ドメイン層
│   │   ├── entities/                # エンティティ
│   │   │   ├── video_item.dart      # 動画アイテム
│   │   │   └── playlist_item.dart   # プレイリストアイテム
│   │   └── repositories/            # リポジトリインターフェース
│   │       └── playlist_repository.dart
│   ├── data/                        # データ層
│   │   ├── datasources/             # データソース
│   │   │   └── shared_preferences_datasource.dart
│   │   └── repositories/            # リポジトリ実装
│   │       └── playlist_repository_impl.dart
│   ├── platform/                    # プラットフォーム固有実装
│   │   ├── youtube_player/          # YouTubeプレイヤー
│   │   │   └── web_player.dart      # Webプレイヤー
│   │   └── stubs/                   # プラットフォームスタブ
│   └── core/                        # コアユーティリティ
│       └── utils/                   # ユーティリティ
│           ├── csv_export.dart      # CSVエクスポート
│           └── csv_import.dart      # CSVインポート
├── script/
│   ├── fetch_videos.py              # YouTube動画情報取得スクリプト
│   └── README.md                    # スクリプトの使用方法
├── pubspec.yaml                     # Flutterプロジェクト設定
└── README.md                        # このファイル
```

## 依存パッケージ

- `file_picker`: JSON/CSVファイルの選択
- `shared_preferences`: データの永続化
- `intl`: 日時フォーマット
- `url_launcher`: 外部ブラウザでのリンク開く

**注意**: `sqflite_common_ffi`は`pubspec.yaml`に含まれていますが、現在の実装では使用されていません。

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
- iframeを使用してYouTube動画を再生するため、インターネット接続が必要です
- GitHub Pagesにデプロイする場合、一部の機能（ファイルシステムへのアクセスなど）が制限される可能性があります
- 開発者モード機能（JSONインポート、音声重視モード）を使用するには、タイトルを5回タップして有効化する必要があります
