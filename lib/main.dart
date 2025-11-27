// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'presentation/app.dart';
import 'data/datasources/shared_preferences_datasource.dart';
import 'data/repositories/playlist_repository_impl.dart';
import 'core/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AnalyticsService.initialize();
  } catch (e) {
    // Firebaseの初期化に失敗した場合でもアプリは動作する
    debugPrint('Firebase initialization failed: $e');
  }

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
