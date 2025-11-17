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

