// lib/data/repositories/track_repository_impl.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/shared_preferences_datasource.dart';

class TrackRepositoryImpl implements TrackRepository {
  final LocalDatabase _localDatabase;
  final SharedPreferencesDataSource _sharedPreferences;
  
  TrackRepositoryImpl({
    required LocalDatabase localDatabase,
    required SharedPreferencesDataSource sharedPreferences,
  })  : _localDatabase = localDatabase,
        _sharedPreferences = sharedPreferences;
  
  @override
  Future<void> initialize() async {
    await _localDatabase.initialize();
    await _sharedPreferences.initialize();
  }
  
  @override
  Future<List<Track>> getAllTracks() async {
    if (kIsWeb) {
      final tracksJson = await _sharedPreferences.getStringList('tracks');
      return tracksJson
          .map((json) =>
              Track.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } else {
      final db = _localDatabase.database;
      if (db == null) return [];
      final rows = await db.query('tracks', orderBy: 'recorded_at DESC');
      return rows.map((r) => Track.fromMap(r)).toList();
    }
  }
  
  @override
  Future<void> saveTrack(Track track) async {
    if (kIsWeb) {
      final tracks = await getAllTracks();
      if (track.id == null) {
        track.id = tracks.length + 1;
      }
      tracks.add(track);
      final tracksJson = tracks.map((t) => jsonEncode(t.toJson())).toList();
      await _sharedPreferences.setStringList('tracks', tracksJson);
    } else {
      final db = _localDatabase.database;
      if (db == null) return;
      final id = await db.insert('tracks', track.toMap());
      track.id = id;
    }
  }
  
  @override
  Future<void> updateTrackEndSec(int trackId, int endSec) async {
    if (kIsWeb) {
      final tracks = await getAllTracks();
      final track = tracks.firstWhere((t) => t.id == trackId);
      track.endSec = endSec;
      final tracksJson = tracks.map((t) => jsonEncode(t.toJson())).toList();
      await _sharedPreferences.setStringList('tracks', tracksJson);
    } else {
      final db = _localDatabase.database;
      if (db == null) return;
      await db.update(
        'tracks',
        {'end_sec': endSec},
        where: 'id = ?',
        whereArgs: [trackId],
      );
    }
  }
  
  @override
  Future<void> deleteTrack(int trackId) async {
    if (kIsWeb) {
      final tracks = await getAllTracks();
      tracks.removeWhere((t) => t.id == trackId);
      final tracksJson = tracks.map((t) => jsonEncode(t.toJson())).toList();
      await _sharedPreferences.setStringList('tracks', tracksJson);
    } else {
      final db = _localDatabase.database;
      if (db == null) return;
      await db.delete('tracks', where: 'id = ?', whereArgs: [trackId]);
    }
  }
}

