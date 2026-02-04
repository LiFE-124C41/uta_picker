// lib/core/utils/web_utils_web.dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void toggleFullScreenImpl() {
  if (web.document.fullscreenElement != null) {
    web.document.exitFullscreen();
  } else {
    web.document.documentElement?.requestFullscreen();
  }
}

void downloadCsvImpl(String content, String fileName) {
  final blob = web.Blob(
      [content.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

void reloadPageImpl() {
  web.window.location.reload();
}
