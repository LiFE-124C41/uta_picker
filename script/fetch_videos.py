# fetch_videos.py
import sys
import requests
import json

def fetch_videos(api_key, channel_id, max_results=50):
    url = "https://www.googleapis.com/youtube/v3/search"
    params = {
        'part': 'snippet',
        'channelId': channel_id,
        'maxResults': max_results,
        'order': 'date',
        'type': 'video',
        'key': api_key
    }
    r = requests.get(url, params=params)
    r.raise_for_status()
    items = r.json().get('items', [])
    videos = []
    for it in items:
        videos.append({
            'videoId': it['id']['videoId'],
            'title': it['snippet']['title'],
            'publishedAt': it['snippet']['publishedAt']
        })
    return videos

def main():
    if len(sys.argv) < 3:
        print("Usage: python fetch_videos.py YOUR_API_KEY CHANNEL_ID")
        print("Example CHANNEL_ID for @xxxxxxx: you can get channelId by visiting the channel and checking source or using the API.")
        return
    api_key = sys.argv[1]
    channel_id = sys.argv[2]
    videos = fetch_videos(api_key, channel_id)
    with open('videos.json', 'w', encoding='utf-8') as f:
        json.dump(videos, f, ensure_ascii=False, indent=2)
    print(f"Saved {len(videos)} videos -> videos.json")

if __name__ == '__main__':
    main()
