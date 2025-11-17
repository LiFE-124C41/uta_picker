// lib/platform/stubs/io_stub.dart
// Stub file for web platform
// This file is used when compiling for web to avoid import errors
import 'dart:convert';

class Platform {
  static const pathSeparator = '/';
}

class File {
  final String path;
  File(this.path);
  
  Future<String> readAsString({Encoding encoding = utf8}) async {
    throw UnimplementedError('File.readAsString not available on web');
  }
  
  Future<void> writeAsString(String contents, {FileMode mode = FileMode.write}) async {
    throw UnimplementedError('File.writeAsString not available on web');
  }
}

enum FileMode { write, append }

