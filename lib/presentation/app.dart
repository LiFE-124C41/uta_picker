// lib/presentation/app.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/playlist_management_page.dart';
import 'pages/playlist_import_page.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../core/services/analytics_service.dart';

class MyApp extends StatelessWidget {
  final PlaylistRepository playlistRepository;

  const MyApp({
    Key? key,
    required this.playlistRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uta(Gawa)Picker',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorObservers: [
        if (AnalyticsService.observer != null) AnalyticsService.observer!,
      ],
      home: HomePage(
        playlistRepository: playlistRepository,
      ),
      routes: {
        '/playlist-management': (context) => PlaylistManagementPage(
              playlistRepository: playlistRepository,
            ),
        '/playlist-import': (context) => PlaylistImportPage(
              playlistRepository: playlistRepository,
            ),
      },
    );
  }
}
