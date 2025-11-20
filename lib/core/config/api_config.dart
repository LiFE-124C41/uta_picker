// lib/core/config/api_config.dart
// File generated automatically during CI/CD build
// Do not commit sensitive values - use GitHub Secrets instead

import 'dart:convert';

/// API設定
/// エンドポイントURLをBase64エンコードして保存
/// CI/CDビルド時にGitHub Secretsから値を取得して生成されます
class ApiConfig {
  // エンコードされたエンドポイントURL
  // この値はCI/CDビルド時にGitHub Secretsから注入されます
  // 開発時は空文字列（エラーが発生します）
  static const String _encodedEndpoint = '{{API_ENDPOINT_BASE64}}';

  /// エンドポイントURLを取得
  static String get endpoint {
    if (_encodedEndpoint == '{{API_ENDPOINT_BASE64}}' ||
        _encodedEndpoint.isEmpty) {
      throw StateError(
        'API endpoint is not configured. '
        'This should be set during CI/CD build from GitHub Secrets.',
      );
    }

    try {
      // Base64デコード
      final bytes = base64Decode(_encodedEndpoint);
      return utf8.decode(bytes);
    } catch (e) {
      throw StateError(
        'Failed to decode API endpoint: $e. '
        'Please check the API_ENDPOINT_BASE64 secret value.',
      );
    }
  }
}
