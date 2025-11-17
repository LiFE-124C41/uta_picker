# fetch_videos.py
import sys
import requests
import json

def fetch_videos(api_key, playlist_id, max_results=50):
    url = "https://www.googleapis.com/youtube/v3/playlistItems"
    params = {
        'part': 'snippet',
        'playlistId': playlist_id,
        'maxResults': max_results,
        'key': api_key
    }
    r = requests.get(url, params=params)
    r.raise_for_status()
    items = r.json().get('items', [])
    videos = []
    for it in items:
        videos.append({
            'videoId': it['snippet']['resourceId']['videoId'],
            'title': it['snippet']['title'],
            'publishedAt': it['snippet']['publishedAt']
        })
    return videos

def main():
    if len(sys.argv) < 3:
        print("Usage: python fetch_videos.py YOUR_API_KEY PLAYLIST_ID")
        print("Example PLAYLIST_ID: you can get playlistId from the playlist URL (e.g., PLxxxxxxx in youtube.com/playlist?list=PLxxxxxxx).")
        return
    api_key = sys.argv[1]
    playlist_id = sys.argv[2]
    videos = fetch_videos(api_key, playlist_id)
    with open('videos.json', 'w', encoding='utf-8') as f:
        json.dump(videos, f, ensure_ascii=False, indent=2)
    print(f"Saved {len(videos)} videos -> videos.json")

if __name__ == '__main__':
    main()
