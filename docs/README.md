# Uta(Gawa)Picker ユーザーマニュアル

このディレクトリには、Uta(Gawa)Pickerアプリケーションのユーザーマニュアルが含まれています。

## ファイル構成

- `index.html`: ユーザーマニュアルのメインページ（日本語）

## 閲覧方法

### ローカルで閲覧する場合

1. `index.html`をブラウザで開く
2. または、ローカルサーバーを起動して閲覧：
   ```bash
   # Python 3の場合
   python -m http.server 8000
   
   # Node.jsの場合
   npx http-server
   ```
3. ブラウザで `http://localhost:8000` にアクセス

### GitHub Pagesで公開する場合

1. `docs`ディレクトリをGitHubリポジトリにプッシュ
2. GitHubリポジトリの「Settings」→「Pages」に移動
3. 「Source」で「/docs」フォルダを選択
4. マニュアルが `https://あなたのユーザー名.github.io/リポジトリ名/` で公開されます

## 画像の追加

マニュアル内には、画像のプレースホルダーが含まれています。実際のスクリーンショットを追加する場合は：

1. `docs/images/`ディレクトリを作成
2. 画像ファイルを配置
3. `index.html`内の画像プレースホルダーを実際の画像パスに置き換え

例：
```html
<!-- プレースホルダー -->
<div class="image-placeholder">
    [画像: 初回起動時の画面スクリーンショット]
</div>

<!-- 実際の画像 -->
<img src="images/initial-screen.png" alt="初回起動時の画面" style="max-width: 100%; margin: 20px 0; border-radius: 5px;">
```

## 更新履歴

- 2024年: 初版作成
