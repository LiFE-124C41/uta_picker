# fetch_comments.py
import sys
import requests
import csv
import re
import json
import time
import html
from googleapiclient.discovery import build
import os
import io
from flask import Response

def clean_html_text(text):
    """
    HTMLタグを除去し、テキストをクリーンアップ
    """
    if not text:
        return ""
    
    # HTMLエンティティをデコード（&amp; → & など）
    text = html.unescape(text)
    
    # <br>タグを改行に変換（その後で改行をスペースに統一）
    text = re.sub(r'<br\s*/?>', '\n', text, flags=re.IGNORECASE)
    
    # その他のHTMLタグを除去
    text = re.sub(r'<[^>]+>', '', text)
    
    # 連続する改行や空白を整理
    text = re.sub(r'\n\s*\n', '\n', text)  # 連続する改行を1つに
    text = re.sub(r'[ \t]+', ' ', text)  # 連続する空白を1つに
    
    # 前後の空白と改行を除去
    text = text.strip()
    
    return text

def parse_timestamp(timestamp_str):
    """
    タイムスタンプ文字列（例: "1:23" や "1:23:45"）を秒数に変換
    """
    parts = timestamp_str.split(':')
    if len(parts) == 2:  # MM:SS
        return int(parts[0]) * 60 + int(parts[1])
    elif len(parts) == 3:  # HH:MM:SS
        return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
    return None

def extract_timestamps_from_text(text):
    """
    コメントテキストからタイムスタンプを抽出
    パターン: "1:23", "1:23:45", "01:23", "01:23:45" など
    """
    # タイムスタンプのパターン（MM:SS または HH:MM:SS）
    pattern = r'\b(\d{1,2}):(\d{2})(?::(\d{2}))?\b'
    matches = re.finditer(pattern, text)
    timestamps = []
    for match in matches:
        timestamp_str = match.group(0)
        seconds = parse_timestamp(timestamp_str)
        if seconds is not None:
            timestamps.append({
                'timestamp': timestamp_str,
                'seconds': seconds,
                'position': match.start()
            })
    return timestamps

def extract_song_title_from_comment(text, timestamp_pos, timestamp_str):
    """
    タイムスタンプの前後から曲名を抽出
    タイムスタンプの位置を基準に、その周辺のテキストから曲名を推測
    """
    # タイムスタンプの直後のテキストを取得（同じ行内または次の行）
    after_pos = timestamp_pos + len(timestamp_str)
    after_text = text[after_pos:after_pos+200].strip()  # 200文字まで取得
    
    if after_text:
        # 改行までのテキストを取得（同じ行内の残り）
        same_line = after_text.split('\n')[0].strip()
        if same_line:
            # タイムスタンプやURLを除去
            cleaned = re.sub(r'[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?', '', same_line)
            cleaned = re.sub(r'https?://\S+', '', cleaned)
            # 余分な空白を整理
            cleaned = re.sub(r'\s+', ' ', cleaned)
            cleaned = cleaned.strip()
            if cleaned and len(cleaned) > 1:
                return cleaned
        
        # 次の行を取得
        lines_after = after_text.split('\n')
        if len(lines_after) > 1:
            next_line = lines_after[1].strip()
            if next_line:
                # タイムスタンプやURLを除去
                cleaned = re.sub(r'[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?', '', next_line)
                cleaned = re.sub(r'https?://\S+', '', cleaned)
                # 余分な空白を整理
                cleaned = re.sub(r'\s+', ' ', cleaned)
                cleaned = cleaned.strip()
                if cleaned and len(cleaned) > 1:
                    return cleaned
    
    # タイムスタンプの前のテキストから抽出（同じ行内）
    before_pos = max(0, timestamp_pos - 100)  # 100文字前まで
    before_text = text[before_pos:timestamp_pos].strip()
    
    if before_text:
        # 最後の行を取得
        lines_before = before_text.split('\n')
        if lines_before:
            last_line = lines_before[-1].strip()
            # タイムスタンプやURLを除去
            cleaned = re.sub(r'[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?', '', last_line)
            cleaned = re.sub(r'https?://\S+', '', cleaned)
            # 余分な空白を整理
            cleaned = re.sub(r'\s+', ' ', cleaned)
            cleaned = cleaned.strip()
            if cleaned and len(cleaned) > 1:
                return cleaned
    
    return ""

def fetch_video_comments(api_key, video_id, max_results=100):
    """
    YouTube Data API v3を使用して動画のコメントを取得
    """
    url = "https://www.googleapis.com/youtube/v3/commentThreads"
    params = {
        'part': 'snippet',
        'videoId': video_id,
        'maxResults': max_results,
        'order': 'relevance',
        'key': api_key
    }
    
    try:
        r = requests.get(url, params=params)
        r.raise_for_status()
        return r.json().get('items', [])
    except requests.exceptions.RequestException as e:
        print(f"Error fetching comments for video {video_id}: {e}")
        return []

def fetch_playlist_videos(api_key, playlist_id, max_results=50):
    """
    プレイリストから動画情報を取得
    """
    url = "https://www.googleapis.com/youtube/v3/playlistItems"
    params = {
        'part': 'snippet',
        'playlistId': playlist_id,
        'maxResults': max_results,
        'key': api_key
    }
    
    try:
        r = requests.get(url, params=params)
        r.raise_for_status()
        items = r.json().get('items', [])
        videos = []
        for it in items:
            videos.append({
                'videoId': it['snippet']['resourceId']['videoId'],
                'title': it['snippet']['title']
            })
        return videos
    except requests.exceptions.RequestException as e:
        print(f"Error fetching playlist videos: {e}")
        return []

def process_comments_to_csv(api_key, playlist_id, output_file='comments.csv', return_csv_string=False):
    """
    プレイリスト内の動画のコメントからタイムスタンプと曲名を抽出し、CSVに出力
    return_csv_string=True の場合、CSV文字列を返す（ファイルには書き込まない）
    """
    # プレイリストから動画を取得
    print(f"Fetching videos from playlist: {playlist_id}")
    videos = fetch_playlist_videos(api_key, playlist_id)
    print(f"Found {len(videos)} videos")
    
    csv_rows = []
    
    for idx, video in enumerate(videos, 1):
        video_id = video['videoId']
        video_title = video['title']
        
        print(f"[{idx}/{len(videos)}] Processing video: {video_title}")
        
        # コメントを取得
        comments = fetch_video_comments(api_key, video_id, max_results=100)
        print(f"  Found {len(comments)} comments")
        
        # タイムスタンプと曲名を抽出
        song_entries = []
        for comment_item in comments:
            # HTMLタグを除去してクリーンアップ
            comment_text = clean_html_text(comment_item['snippet']['topLevelComment']['snippet']['textDisplay'])
            timestamps = extract_timestamps_from_text(comment_text)
            
            for ts_info in timestamps:
                # タイムスタンプの位置と文字列を渡して曲名を抽出
                song_title = extract_song_title_from_comment(comment_text, ts_info['position'], ts_info['timestamp'])
                
                if song_title or ts_info['seconds'] > 0:  # タイムスタンプがあれば記録
                    # 曲名もクリーンアップ（念のため）
                    song_title_clean = re.sub(r'\s+', ' ', song_title).strip() if song_title else f"曲@{ts_info['timestamp']}"
                    song_entries.append({
                        'start_sec': ts_info['seconds'],
                        'song_title': song_title_clean,
                        'timestamp': ts_info['timestamp']
                    })
        
        # タイムスタンプでソート
        song_entries.sort(key=lambda x: x['start_sec'])
        
        # 終了時間を計算（次のタイムスタンプまたは動画の終了）
        for i, entry in enumerate(song_entries):
            if i < len(song_entries) - 1:
                entry['end_sec'] = song_entries[i + 1]['start_sec']
            else:
                # 最後のエントリは動画の終了時間を取得する必要があるが、
                # ここでは開始時間+300秒（5分）をデフォルトとする
                entry['end_sec'] = entry['start_sec'] + 300
        
        # CSV行を作成
        for entry in song_entries:
            link = f"https://www.youtube.com/watch?v={video_id}&t={entry['start_sec']}s"
            csv_rows.append({
                'video_title': video_title,
                'song_title': entry['song_title'],
                'video_id': video_id,
                'start_sec': entry['start_sec'],
                'end_sec': entry['end_sec'],
                'link': link
            })
        
        # APIレート制限を避けるため、少し待機
        time.sleep(0.1)
    
    # CSVを生成
    if csv_rows:
        fieldnames = ['video_title', 'song_title', 'video_id', 'start_sec', 'end_sec', 'link']
        
        if return_csv_string:
            # メモリ内でCSV文字列を生成
            output = io.StringIO()
            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(csv_rows)
            csv_string = output.getvalue()
            output.close()
            print(f"\nGenerated {len(csv_rows)} entries as CSV string")
            return csv_string
        else:
            # ファイルに書き込み
            with open(output_file, 'w', encoding='utf-8', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(csv_rows)
            print(f"\nSaved {len(csv_rows)} entries to {output_file}")
            return None
    else:
        print("\nNo entries found to save.")
        return "" if return_csv_string else None

def comments(request):
    """
    Cloud Function用のエントリーポイント
    CSVをレスポンスとして返す
    """
    # CORSヘッダーを定義
    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS, GET',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '3600'
    }
    
    # OPTIONSリクエスト（プリフライト）への対応
    if request.method == 'OPTIONS':
        return Response(
            '',
            status=204,
            headers=cors_headers
        )
    
    api_key = os.getenv("YOUTUBE_API_KEY")
    if not api_key:
        return Response(
            json.dumps({"error": "YOUTUBE_API_KEY environment variable is not set"}),
            status=500,
            mimetype='application/json',
            headers=cors_headers
        )
    
    playlist_id = request.args.get("playlist_id")
    if not playlist_id:
        return Response(
            json.dumps({"error": "playlist_id parameter is required"}),
            status=400,
            mimetype='application/json',
            headers=cors_headers
        )
    
    try:
        # CSV文字列を取得
        csv_string = process_comments_to_csv(api_key, playlist_id, return_csv_string=True)
        
        # CSVをレスポンスとして返す（CORSヘッダーを追加）
        headers = {
            'Content-Disposition': 'attachment; filename=comments.csv'
        }
        headers.update(cors_headers)
        
        return Response(
            csv_string,
            mimetype='text/csv; charset=utf-8',
            headers=headers
        )
    except Exception as e:
        return Response(
            json.dumps({"error": str(e)}),
            status=500,
            mimetype='application/json',
            headers=cors_headers
        )

def main():
    if len(sys.argv) < 3:
        print("Usage: python fetch_comments.py YOUR_API_KEY PLAYLIST_ID [OUTPUT_FILE]")
        print("Example: python fetch_comments.py AIzaSy... PLxxxxxxx comments.csv")
        return
    
    api_key = sys.argv[1]
    playlist_id = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else 'comments.csv'
    
    process_comments_to_csv(api_key, playlist_id, output_file)

if __name__ == '__main__':
    main()

