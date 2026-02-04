// lib/data/datasources/shared_preferences_datasource.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SharedPreferencesDataSource {
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  SharedPreferences? get prefs => _prefs;

  Future<List<String>> getStringList(String key) async {
    if (!kIsWeb || _prefs == null) return [];
    return _prefs!.getStringList(key) ?? [];
  }

  Future<void> setStringList(String key, List<String> value) async {
    if (!kIsWeb || _prefs == null) return;
    await _prefs!.setStringList(key, value);
  }

  bool containsKey(String key) {
    if (!kIsWeb || _prefs == null) return false;
    return _prefs!.containsKey(key);
  }
}
