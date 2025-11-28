# uta_picker

A Flutter application for marking the start and end times of songs in YouTube archive videos.

[English](README.en.md) | [日本語](README.md)

![GitHub release](https://img.shields.io/github/v/release/life-124c41/uta_picker)
[![Deploy Status](https://github.com/life-124c41/uta_picker/actions/workflows/deploy.yml/badge.svg)](https://github.com/life-124c41/uta_picker/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/github/license/life-124c41/uta_picker.svg)](https://github.com/LiFE-124C41/uta_picker/blob/main/LICENSE)
![oshi](https://img.shields.io/badge/%E2%9D%A4%EF%B8%8F%E2%80%8D%F0%9F%94%A5%F0%9F%88%81%E2%9A%A1-fave-656a75)

## Overview

This application allows you to create and save playlists by specifying the start and end times of each song in YouTube archive videos (such as live stream recordings). Created playlists can be played continuously, and can be exported and imported in CSV format.

## Deployment

The web version of this application is published at the following URL:

🔗 **https://life-124c41.github.io/uta_picker/**

## Main Features

- **Video Playback**: Play YouTube videos within the app using iframe
- **Playlist Creation**: Create playlist items by specifying start and end times of videos
- **Playlist Playback**:
  - Continuously play created playlists
  - **Repeat**: Supports single track repeat and full playlist repeat
  - **Shuffle**: Play the playlist in a random order
- **Playlist Management**: Add, edit, delete, and reorder playlist items
- **Data Storage**: Save playlists to SharedPreferences
- **CSV Export/Import**: Export and import playlists in CSV format
- **YouTube URL Parser**: Automatically extract video ID from YouTube URLs
- **Responsive UI**: Optimized for various screen sizes, including PCs and smartphones
- **User Manual**: Access the user manual from within the app
- **Firebase Analytics**: Track app usage (optional)

## Requirements

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Supported Platform: Web

## Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd uta_picker
```

2. Install dependencies:

```bash
flutter pub get
```

## Usage

### 1. Prepare Video List

First, use `script/fetch_videos.py` to retrieve video information from a YouTube playlist. For details, refer to [script/README.md](script/README.md).

```bash
cd script
python fetch_videos.py YOUR_API_KEY PLAYLIST_ID
```

This will generate a `videos.json` file.

**Optional**: You can also use `script/fetch_comments.py` to extract timestamps from YouTube video comments.

### 2. Launch the App

```bash
flutter run
```

### 3. Import Video List (Developer Mode)

1. After launching the app, tap the title "UtaPicker" 5 times to enable developer mode
2. Click the "Create Playlist from JSON" button (📤 icon) in the top right
3. Select the `videos.json` file
4. The video list will be displayed

### 4. Add to Playlist

1. **Add from Video List**:
   - Select a video from the video list
   - Click the "Add to Playlist" button (➕ icon)
   - Enter start and end times in "MM:SS" or "HH:MM:SS" format (e.g., `00:30` or `01:07:52`)
   - Enter video title and song title (optional)
   - Click "Add"

2. **Add from Playlist Management Screen**:
   - Click the "Playlist Management" button (⚙️ icon) in the top right
   - Click the "+" button
   - Enter video ID, start time, and end time
   - Click "Add"

### 5. Play Playlist

1. **Playback Controls**:
   - ▶️ **Play**: Start continuous playback of the playlist.
   - ⏹️ **Stop**: Stop continuous playback.
   - 🔁 **Repeat**: Toggle repeat mode: "No Repeat" -> "Repeat One" -> "Repeat All".
   - 🔀 **Shuffle**: Enable/disable shuffle playback for the playlist.
2. **Individual Playback**:
   - Selecting an item from the playlist will play that song.
3. **Header Icons**:
   - 🔄 **Reload** (Web only): Reload the page.
   - ❓ **User Manual**: Open the user manual for instructions.

### 6. Manage Playlist

1. Click the "Playlist Management" button (⚙️ icon) in the top right
2. You can edit, delete, and reorder playlist items
3. CSV import/export can also be performed from here

## Other Features

- **Playlist Management**: Add, edit, delete, and reorder items
- **Repeat Playback**: Single track repeat and full playlist repeat
- **Shuffle Playback**: Random playback of the playlist
- **CSV Import**: Bulk import playlists from CSV files
- **CSV Export**: Export playlists in CSV format
- **Audio-Focused Mode** (Developer mode only): Playback mode with low resolution focused on audio

## Data Storage Format

The application saves playlists using SharedPreferences. Each playlist item contains the following information:

- `video_id`: YouTube video ID
- `start_sec`: Start time (seconds)
- `end_sec`: End time (seconds)
- `video_title`: Video title (optional)
- `song_title`: Song title (optional)

## Export Format

CSV files contain the following columns:

- `video_title`: Video title
- `song_title`: Song title
- `video_id`: YouTube video ID
- `start_sec`: Start time (seconds)
- `end_sec`: End time (seconds)
- `link`: YouTube timestamp link (format: `https://youtu.be/{video_id}?t={start_sec}`)

When importing CSV, you can load CSV files in the same format.

## Project Structure

```
uta_picker/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── presentation/                # UI layer
│   │   ├── app.dart                 # Application root
│   │   ├── pages/                   # Page components
│   │   │   ├── home_page.dart       # Home page
│   │   │   ├── playlist_management_page.dart  # Playlist management page
│   │   │   └── playlist_import_page.dart       # JSON import page
│   │   └── widgets/                 # Widgets
│   │       └── youtube_list_download_dialog.dart  # YouTube list download dialog
│   ├── domain/                      # Domain layer
│   │   ├── entities/                # Entities
│   │   │   ├── video_item.dart      # Video item
│   │   │   └── playlist_item.dart    # Playlist item
│   │   └── repositories/            # Repository interfaces
│   │       └── playlist_repository.dart
│   ├── data/                        # Data layer
│   │   ├── datasources/             # Data sources
│   │   │   └── shared_preferences_datasource.dart
│   │   └── repositories/            # Repository implementations
│   │       └── playlist_repository_impl.dart
│   ├── platform/                    # Platform-specific implementations
│   │   ├── youtube_player/          # YouTube player
│   │   │   ├── web_player.dart      # Web player
│   │   │   └── desktop_player.dart  # Desktop player
│   │   └── stubs/                   # Platform stubs
│   └── core/                        # Core utilities
│       ├── config/                  # Configuration
│       │   └── api_config.dart      # API configuration
│       ├── services/                # Services
│       │   └── analytics_service.dart  # Analytics service
│       └── utils/                   # Utilities
│           ├── csv_export.dart      # CSV export
│           ├── csv_import.dart      # CSV import
│           ├── time_format.dart     # Time format
│           └── youtube_url_parser.dart  # YouTube URL parser
├── assets/
│   └── logo.png                     # Application logo
├── docs/
│   └── index.html                   # User manual
├── script/
│   ├── fetch_videos.py              # YouTube video information retrieval script
│   ├── fetch_comments.py            # YouTube comments retrieval script
│   └── README.md                    # Script usage instructions
├── pubspec.yaml                     # Flutter project configuration
└── README.md                        # This file
```

## Dependencies

- `file_picker`: Select JSON/CSV files
- `shared_preferences`: Data persistence
- `intl`: Date/time formatting
- `url_launcher`: Open links in external browser
- `webview_flutter`: YouTube video playback on desktop platforms
- `path_provider`: Get file paths
- `package_info_plus`: Get app information
- `firebase_core`: Firebase core functionality
- `firebase_analytics`: Firebase Analytics
- `http`: HTTP requests

**Note**: `sqflite_common_ffi` is included in `pubspec.yaml` but is not currently used in the implementation.

## License

For license information about this project, please refer to the [LICENSE](LICENSE) file.

## Firebase Analytics Setup

This app uses Firebase Analytics. Configuration is required for both local development and deployment.

### Local Development Environment Setup

1. Create a project in Firebase Console (https://console.firebase.google.com/)
2. Add a web app and obtain configuration information
3. Copy `lib/firebase_options.dart.example` to create `lib/firebase_options.dart`
4. Enter the configuration values obtained from Firebase Console into `lib/firebase_options.dart`

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Then edit firebase_options.dart and enter the actual values
```

**Note**: `lib/firebase_options.dart` contains sensitive information and is not committed to Git (excluded in `.gitignore`).

### GitHub Actions Deployment Configuration

To automatically generate Firebase configuration during deployment, set the following values in GitHub Secrets:

1. Go to your GitHub repository's "Settings" → "Secrets and variables" → "Actions"
2. Click "New repository secret" and add the following Secrets:

**Required (for Web app):**
- `FIREBASE_API_KEY`: Firebase Web app API key
- `FIREBASE_APP_ID`: Firebase Web app App ID (e.g., `1:123456789:web:abcdef`)
- `FIREBASE_MESSAGING_SENDER_ID`: Messaging Sender ID
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `FIREBASE_AUTH_DOMAIN`: Auth Domain (e.g., `your-project.firebaseapp.com`)
- `FIREBASE_STORAGE_BUCKET`: Storage Bucket (e.g., `your-project.appspot.com`)
- `FIREBASE_MEASUREMENT_ID`: Measurement ID (for Google Analytics, e.g., `G-XXXXXXXXXX`)

**Optional (for Android/iOS/macOS apps):**
- `FIREBASE_ANDROID_API_KEY`: Android app API key
- `FIREBASE_ANDROID_APP_ID`: Android app App ID
- `FIREBASE_IOS_API_KEY`: iOS app API key
- `FIREBASE_IOS_APP_ID`: iOS app App ID
- `FIREBASE_MACOS_API_KEY`: macOS app API key
- `FIREBASE_MACOS_APP_ID`: macOS app App ID

These values can be obtained from Firebase Console's "Project Settings" → "Your apps".

## Deployment to GitHub Pages

Steps to deploy the web version of this app to GitHub Pages:

### 1. GitHub Pages Configuration

1. Go to your GitHub repository's "Settings" → "Pages"
2. Select "GitHub Actions" under "Source"

### 2. Workflow Verification

The `.github/workflows/deploy.yml` file has been created. Please verify the following points in this file:

- Whether your main branch name (`main` or `master`) is specified in the `branches` section
- Whether `base-href` matches your repository name (default is `/uta_picker/`)

If your repository name is different, modify the following line in `.github/workflows/deploy.yml`:

```yaml
run: flutter build web --base-href "/uta_picker/" --release
```

Change `/uta_picker/` to `/your-repository-name/`.

### 3. Execute Deployment

1. Manually run the "Deploy to GitHub Pages" workflow from the "Actions" tab
2. Select the version increment type (patch/minor/major)
3. Once deployment is complete, you can access it at `https://your-username.github.io/uta_picker/`

### 4. Local Verification

To build and verify locally:

```bash
flutter build web --base-href "/uta_picker/" --release
cd build/web
# Verify with a local server (e.g., Python)
python -m http.server 8000
```

## Notes

- When using YouTube Data API, please be mindful of API key usage limits
- Internet connection is required as YouTube videos are played using iframe
- When deploying to GitHub Pages, some features (such as file system access) may be limited
- To use developer mode features (JSON import, audio-focused mode), you need to enable it by tapping the title 5 times

