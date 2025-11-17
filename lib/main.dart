// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'presentation/app.dart';
import 'data/datasources/local_database.dart';
import 'data/datasources/shared_preferences_datasource.dart';
import 'data/repositories/track_repository_impl.dart';
import 'data/repositories/playlist_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop only (Web uses shared_preferences)
  if (!kIsWeb) {
    sqfliteFfiInit();
    // databaseFactory is set globally in sqflite_common
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize data sources
  final localDatabase = LocalDatabase();
  final sharedPreferences = SharedPreferencesDataSource();
  
  // Initialize repositories
  final trackRepository = TrackRepositoryImpl(
    localDatabase: localDatabase,
    sharedPreferences: sharedPreferences,
  );
  final playlistRepository = PlaylistRepositoryImpl(
    sharedPreferences: sharedPreferences,
  );

  runApp(MyApp(
    trackRepository: trackRepository,
    playlistRepository: playlistRepository,
  ));
}
