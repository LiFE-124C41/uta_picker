import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uta_picker/data/datasources/shared_preferences_datasource.dart';
import 'package:uta_picker/data/repositories/playlist_repository_impl.dart';
import 'package:uta_picker/domain/entities/playlist_item.dart';

@GenerateMocks([SharedPreferencesDataSource])
import 'playlist_repository_impl_test.mocks.dart';

void main() {
  late PlaylistRepositoryImpl repository;
  late MockSharedPreferencesDataSource mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferencesDataSource();
    repository = PlaylistRepositoryImpl(
      sharedPreferences: mockSharedPreferences,
      isWeb: true,
    );
  });

  group('PlaylistRepositoryImpl', () {
    final tPlaylistItem = PlaylistItem(
      videoId: 'test_id',
      videoTitle: 'Test Video',
      songTitle: 'Test Song',
    );
    final tPlaylist = [tPlaylistItem];
    final tPlaylistJson = [jsonEncode(tPlaylistItem.toJson())];

    test('getPlaylist returns list of PlaylistItem', () async {
      when(mockSharedPreferences.getStringList('playlist'))
          .thenAnswer((_) async => tPlaylistJson);

      final result = await repository.getPlaylist();

      expect(result.length, 1);
      expect(result.first.videoId, tPlaylistItem.videoId);
      verify(mockSharedPreferences.getStringList('playlist'));
    });

    test('savePlaylist saves list of PlaylistItem', () async {
      when(mockSharedPreferences.setStringList('playlist', any))
          .thenAnswer((_) async => {});

      await repository.savePlaylist(tPlaylist);

      verify(mockSharedPreferences.setStringList('playlist', tPlaylistJson));
    });

    test('addPlaylistItem adds item and saves', () async {
      when(mockSharedPreferences.getStringList('playlist'))
          .thenAnswer((_) async => []);
      when(mockSharedPreferences.setStringList('playlist', any))
          .thenAnswer((_) async => {});

      await repository.addPlaylistItem(tPlaylistItem);

      verify(mockSharedPreferences.getStringList('playlist'));
      verify(mockSharedPreferences.setStringList('playlist', tPlaylistJson));
    });

    test('updatePlaylistItem updates item and saves', () async {
      when(mockSharedPreferences.getStringList('playlist'))
          .thenAnswer((_) async => tPlaylistJson);
      when(mockSharedPreferences.setStringList('playlist', any))
          .thenAnswer((_) async => {});

      final updatedItem = PlaylistItem(
        videoId: 'test_id',
        videoTitle: 'Updated Video',
        songTitle: 'Updated Song',
      );
      final updatedPlaylistJson = [jsonEncode(updatedItem.toJson())];

      await repository.updatePlaylistItem(0, updatedItem);

      verify(mockSharedPreferences.getStringList('playlist'));
      verify(
          mockSharedPreferences.setStringList('playlist', updatedPlaylistJson));
    });

    test('removePlaylistItem removes item and saves', () async {
      when(mockSharedPreferences.getStringList('playlist'))
          .thenAnswer((_) async => tPlaylistJson);
      when(mockSharedPreferences.setStringList('playlist', any))
          .thenAnswer((_) async => {});

      await repository.removePlaylistItem(0);

      verify(mockSharedPreferences.getStringList('playlist'));
      verify(mockSharedPreferences.setStringList('playlist', []));
    });

    test('clearPlaylist clears playlist', () async {
      when(mockSharedPreferences.setStringList('playlist', any))
          .thenAnswer((_) async => {});

      await repository.clearPlaylist();

      verify(mockSharedPreferences.setStringList('playlist', []));
    });
  });
}
