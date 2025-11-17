# Script ディレクトリ

このディレクトリには、YouTubeチャンネルの動画情報を取得するためのスクリプトが含まれています。

## fetch_videos.py

YouTube Data API v3を使用して、指定されたチャンネルの動画情報を取得し、JSONファイルに保存するスクリプトです。

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
python fetch_videos.py YOUR_API_KEY CHANNEL_ID
```

#### パラメータ

- `YOUR_API_KEY`: YouTube Data API v3のAPIキー
- `CHANNEL_ID`: 取得したいYouTubeチャンネルのID（`UC`で始まる文字列）

#### 実行例

```bash
python fetch_videos.py AIzaSy... UCxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 出力

スクリプトは、指定されたチャンネルの最新動画情報を`videos.json`ファイルに保存します。デフォルトでは最新50件の動画を取得します。

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

### チャンネルIDの取得方法

チャンネルIDは以下の方法で取得できます：

1. **YouTubeチャンネルページから取得**
   - チャンネルページを開く
   - ページのソースコードを表示（右クリック→「ページのソースを表示」）
   - `"channelId":"UC...` を検索して見つける

2. **YouTube Data APIを使用**
   - チャンネルのユーザー名（例：@xxxx）からチャンネルIDを取得

### 注意事項

- APIキーは安全に管理してください。公開リポジトリにコミットしないよう注意してください
- YouTube Data APIには1日のリクエスト数に制限があります（デフォルトで10,000ユニット/日）
- チャンネルIDは`UC`で始まる文字列です（例：`UCxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`）
- 出力ファイル`videos.json`は、スクリプトを実行したディレクトリに作成されます

