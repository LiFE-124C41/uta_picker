// lib/data/repositories/playlist_repository_impl.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/entities/playlist_item.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/shared_preferences_datasource.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final SharedPreferencesDataSource _sharedPreferences;
  final bool _isWeb;

  PlaylistRepositoryImpl({
    required SharedPreferencesDataSource sharedPreferences,
    bool isWeb = kIsWeb,
  })  : _sharedPreferences = sharedPreferences,
        _isWeb = isWeb;

  Future<void> initialize() async {
    await _sharedPreferences.initialize();
  }

  @override
  Future<List<PlaylistItem>> getPlaylist() async {
    if (!_isWeb) return [];

    // キーが存在しない場合は初回起動とみなしてデフォルトのプレイリストを設定
    if (!_sharedPreferences.containsKey('playlist')) {
      final defaultPlaylist = _getDefaultPlaylist();
      await savePlaylist(defaultPlaylist);
      return defaultPlaylist;
    }

    final playlistJson = await _sharedPreferences.getStringList('playlist');
    return playlistJson
        .map((json) =>
            PlaylistItem.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  List<PlaylistItem> _getDefaultPlaylist() {
    return [
      PlaylistItem(
        videoId: 't7RGIiMn9Po',
        songTitle: 'ともすれば、（中略）アイドル',
      ),
      PlaylistItem(
        videoId: 'vRMWpa9x_rs',
        songTitle: 'Berry Berry Lady',
      ),
      PlaylistItem(
        videoId: 'zBmNvRC6JgY',
        songTitle: 'エキセントリック・ラブ',
      ),
      PlaylistItem(
        videoId: 's6M84IH4m8k',
        songTitle: '公転周期',
      ),
      PlaylistItem(
        videoId: '-J3OnxCEzl0',
        songTitle: 'ZeroGravity',
      ),
      PlaylistItem(
        videoId: 'gB89fpqSvAM',
        songTitle: 'No.8',
      ),
      PlaylistItem(
        videoId: 'acjR8k46mKg',
        songTitle: '群青イニシエーション',
      ),
      PlaylistItem(
        videoId: 'q0ECuIJNpZw',
        songTitle: 'アエルシグナル',
      ),
      PlaylistItem(
        videoId: '7A2gsj8lL-E',
        songTitle: 'Glass',
      ),
      PlaylistItem(
        videoId: 'nzkHHR2CUEM',
        songTitle: 'リローディング',
      ),
      PlaylistItem(
        videoId: 'iNmuKTcSIL8',
        songTitle: 'ヴヴヴ',
      ),
      PlaylistItem(
        videoId: 'uXO2CzVsOmM',
        songTitle: 'まだ見ぬ明日',
      ),
    ];
  }

  @override
  Future<void> savePlaylist(List<PlaylistItem> playlist) async {
    if (!_isWeb) return;
    final playlistJson = playlist.map((p) => jsonEncode(p.toJson())).toList();
    await _sharedPreferences.setStringList('playlist', playlistJson);
  }

  @override
  Future<void> addPlaylistItem(PlaylistItem item) async {
    final playlist = await getPlaylist();
    playlist.add(item);
    await savePlaylist(playlist);
  }

  @override
  Future<void> updatePlaylistItem(int index, PlaylistItem item) async {
    final playlist = await getPlaylist();
    if (index >= 0 && index < playlist.length) {
      playlist[index] = item;
      await savePlaylist(playlist);
    }
  }

  @override
  Future<void> removePlaylistItem(int index) async {
    final playlist = await getPlaylist();
    if (index >= 0 && index < playlist.length) {
      playlist.removeAt(index);
      await savePlaylist(playlist);
    }
  }

  @override
  Future<void> clearPlaylist() async {
    await savePlaylist([]);
  }
}
