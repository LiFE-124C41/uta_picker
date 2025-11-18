# Script ディレクトリ

このディレクトリには、YouTubeプレイリストの動画情報を取得するためのスクリプトが含まれています。

## fetch_videos.py

YouTube Data API v3を使用して、指定されたプレイリストの動画情報を取得し、JSONファイルに保存するスクリプトです。

### 必要な環境

- Python 3.x
- `requests` ライブラリ

### インストール

必要なPythonパッケージをインストールします：

```bash
pip install requests
```

### 使用方法

```bash
python fetch_videos.py YOUR_API_KEY PLAYLIST_ID
```

#### パラメータ

- `YOUR_API_KEY`: YouTube Data API v3のAPIキー
- `PLAYLIST_ID`: 取得したいYouTubeプレイリストのID（`PL`で始まる文字列）

#### 実行例

```bash
python fetch_videos.py AIzaSy... PLxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 出力

スクリプトは、指定されたプレイリストの動画情報を`videos.json`ファイルに保存します。デフォルトでは最大50件の動画を取得します。

出力されるJSONファイルの形式：

```json
[
    {
        "videoId": "abcd1234",
        "title": "動画タイトル",
        "publishedAt": "2025-10-01T20:00:00Z"
    }
]
```

### YouTube Data API キーの取得方法

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. 新しいプロジェクトを作成（または既存のプロジェクトを選択）
3. 「APIとサービス」→「ライブラリ」から「YouTube Data API v3」を有効化
4. 「認証情報」→「認証情報を作成」→「APIキー」を選択
5. 作成されたAPIキーをコピー

### プレイリストIDの取得方法

プレイリストIDは以下の方法で取得できます：

1. **YouTubeプレイリストURLから取得**
   - プレイリストページを開く
   - URLの`list=`パラメータの値をコピー（例：`youtube.com/playlist?list=PLxxxxxxx` の場合、`PLxxxxxxx`がプレイリストID）
   - プレイリストIDは通常`PL`で始まる文字列です

2. **YouTube Data APIを使用**
   - チャンネルIDからプレイリスト一覧を取得し、目的のプレイリストIDを特定

### 注意事項

- APIキーは安全に管理してください。公開リポジトリにコミットしないよう注意してください
- YouTube Data APIには1日のリクエスト数に制限があります（デフォルトで10,000ユニット/日）
- プレイリストIDは通常`PL`で始まる文字列です（例：`PLxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`）
- 出力ファイル`videos.json`は、スクリプトを実行したディレクトリに作成されます
- プレイリストに含まれる動画数が`maxResults`（デフォルト50件）を超える場合、最初の50件のみが取得されます

## fetch_comments.py

YouTube Data API v3を使用して、指定されたプレイリスト内の動画のコメントからタイムスタンプと曲名を抽出し、CSVファイルに保存するスクリプトです。

### 機能

- プレイリスト内の全動画のコメントを取得
- コメントテキストからタイムスタンプ（例: "1:23", "1:23:45"）を抽出
- タイムスタンプの前後から曲名を自動抽出
- 抽出した情報をCSVファイルに出力

### 必要な環境

- Python 3.x
- `requests` ライブラリ

### インストール

必要なPythonパッケージをインストールします：

```bash
pip install requests
```

### 使用方法

```bash
python fetch_comments.py YOUR_API_KEY PLAYLIST_ID [OUTPUT_FILE]
```

#### パラメータ

- `YOUR_API_KEY`: YouTube Data API v3のAPIキー
- `PLAYLIST_ID`: 取得したいYouTubeプレイリストのID（`PL`で始まる文字列）
- `OUTPUT_FILE`: 出力するCSVファイル名（オプション、デフォルト: `comments.csv`）

#### 実行例

```bash
python fetch_comments.py AIzaSy... PLxxxxxxxxxxxxxxxxxxxxxxxxxxxxx comments.csv
```

### 出力

スクリプトは、プレイリスト内の動画のコメントから抽出したタイムスタンプと曲名をCSVファイルに保存します。

出力されるCSVファイルの形式：

```csv
video_title,song_title,video_id,start_sec,end_sec,link
動画タイトル,曲名,abcd1234,83,180,https://www.youtube.com/watch?v=abcd1234&t=83s
```

#### CSVの各カラム

- `video_title`: 動画のタイトル
- `song_title`: 抽出された曲名（タイムスタンプの前後から自動抽出）
- `video_id`: YouTube動画ID
- `start_sec`: 曲の開始時間（秒）
- `end_sec`: 曲の終了時間（秒、次のタイムスタンプまたは開始時間+300秒）
- `link`: 動画の該当時間へのリンク

### 主な関数

#### `clean_html_text(text)`
HTMLタグを除去し、テキストをクリーンアップします。

#### `parse_timestamp(timestamp_str)`
タイムスタンプ文字列（例: "1:23" や "1:23:45"）を秒数に変換します。

#### `extract_timestamps_from_text(text)`
コメントテキストからタイムスタンプを抽出します。パターン: "1:23", "1:23:45", "01:23", "01:23:45" など。

#### `extract_song_title_from_comment(text, timestamp_pos, timestamp_str)`
タイムスタンプの前後から曲名を抽出します。タイムスタンプの位置を基準に、その周辺のテキストから曲名を推測します。

#### `fetch_video_comments(api_key, video_id, max_results=100)`
YouTube Data API v3を使用して動画のコメントを取得します。

#### `fetch_playlist_videos(api_key, playlist_id, max_results=50)`
プレイリストから動画情報を取得します。

#### `process_comments_to_csv(api_key, playlist_id, output_file='comments.csv')`
プレイリスト内の動画のコメントからタイムスタンプと曲名を抽出し、CSVに出力します。

### 注意事項

- APIキーは安全に管理してください。公開リポジトリにコミットしないよう注意してください
- YouTube Data APIには1日のリクエスト数に制限があります（デフォルトで10,000ユニット/日）
- コメント取得には時間がかかる場合があります（APIレート制限を避けるため、各動画の処理後に0.1秒待機）
- タイムスタンプが見つからないコメントはスキップされます
- 曲名が抽出できない場合は、`曲@タイムスタンプ`の形式で記録されます
- 最後のエントリの終了時間は、開始時間+300秒（5分）がデフォルトとして設定されます
- 出力ファイル`comments.csv`は、スクリプトを実行したディレクトリに作成されます

