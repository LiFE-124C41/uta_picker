// lib/platform/stubs/webview_stub.dart
// Stub file for web platform
// This file is used when compiling for web to avoid import errors
import 'package:flutter/widgets.dart';

class WebViewController {
  void setJavaScriptMode(dynamic mode) {}
  void addJavaScriptChannel(String name, {required Function(dynamic) onMessageReceived}) {}
  Future<void> loadRequest(Uri uri) async {}
  Future<void> runJavaScript(String code) async {}
}

class JavaScriptMode {
  static const unrestricted = JavaScriptMode._();
  const JavaScriptMode._();
}

class JavaScriptMessage {
  final String message;
  JavaScriptMessage(this.message);
}

class WebViewWidget extends Widget {
  final dynamic controller;
  WebViewWidget({required this.controller});
  
  @override
  Element createElement() {
    throw UnimplementedError('WebViewWidget not available on web');
  }
}

