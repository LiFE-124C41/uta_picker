// lib/data/repositories/playlist_repository_impl.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/entities/playlist_item.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/shared_preferences_datasource.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final SharedPreferencesDataSource _sharedPreferences;
  
  PlaylistRepositoryImpl({
    required SharedPreferencesDataSource sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;
  
  Future<void> initialize() async {
    await _sharedPreferences.initialize();
  }
  
  @override
  Future<List<PlaylistItem>> getPlaylist() async {
    if (!kIsWeb) return [];
    final playlistJson = await _sharedPreferences.getStringList('playlist');
    return playlistJson
        .map((json) =>
            PlaylistItem.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }
  
  @override
  Future<void> savePlaylist(List<PlaylistItem> playlist) async {
    if (!kIsWeb) return;
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

