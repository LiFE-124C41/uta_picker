// lib/main.dart
import 'package:flutter/material.dart';

import 'presentation/app.dart';
import 'data/datasources/shared_preferences_datasource.dart';
import 'data/repositories/playlist_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize data sources
  final sharedPreferences = SharedPreferencesDataSource();
  
  // Initialize repositories
  final playlistRepository = PlaylistRepositoryImpl(
    sharedPreferences: sharedPreferences,
  );

  runApp(MyApp(
    playlistRepository: playlistRepository,
  ));
}
