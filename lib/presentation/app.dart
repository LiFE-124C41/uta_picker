// lib/presentation/app.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/playlist_management_page.dart';
import '../../domain/repositories/track_repository.dart';
import '../../domain/repositories/playlist_repository.dart';

class MyApp extends StatelessWidget {
  final TrackRepository trackRepository;
  final PlaylistRepository playlistRepository;
  
  const MyApp({
    Key? key,
    required this.trackRepository,
    required this.playlistRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song Picker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(
        trackRepository: trackRepository,
        playlistRepository: playlistRepository,
      ),
      routes: {
        '/playlist-management': (context) => PlaylistManagementPage(
          playlistRepository: playlistRepository,
        ),
      },
    );
  }
}

