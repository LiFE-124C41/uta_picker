// lib/data/datasources/local_database.dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io_platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDatabase {
  Database? _db;
  
  Future<void> initialize() async {
    if (kIsWeb) {
      return; // Webでは使用しない
    }
    
    final documentsDir = await getApplicationSupportDirectory();
    final dbPath =
        '${documentsDir.path}${io_platform.Platform.pathSeparator}song_picker.db';
    _db = await databaseFactory.openDatabase(dbPath);
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id TEXT,
        video_title TEXT,
        start_sec INTEGER,
        end_sec INTEGER,
        song_title TEXT,
        recorded_at TEXT,
        note TEXT
      );
    ''');
  }
  
  Database? get database => _db;
  
  Future<void> close() async {
    await _db?.close();
  }
}

