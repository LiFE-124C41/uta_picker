// lib/platform/stubs/ui_web_stub.dart
// Stub file for non-web platforms
// This file is used when compiling for non-web platforms to avoid import errors

class PlatformViewRegistry {
  void registerViewFactory(String viewType, dynamic factory) {
    // No-op on non-web platforms
  }
}

final platformViewRegistry = PlatformViewRegistry();

