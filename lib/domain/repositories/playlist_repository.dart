// lib/domain/repositories/playlist_repository.dart
import '../entities/playlist_item.dart';

abstract class PlaylistRepository {
  Future<List<PlaylistItem>> getPlaylist();
  Future<void> savePlaylist(List<PlaylistItem> playlist);
  Future<void> addPlaylistItem(PlaylistItem item);
  Future<void> removePlaylistItem(int index);
  Future<void> clearPlaylist();
}

