// lib/core/utils/web_utils_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void toggleFullScreenImpl() {
  if (html.document.fullscreenElement != null) {
    html.document.exitFullscreen();
  } else {
    html.document.documentElement?.requestFullscreen();
  }
}
