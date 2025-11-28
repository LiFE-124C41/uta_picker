// lib/platform/stubs/js_stub.dart
// Stub file for non-web platforms
// This file is used when compiling for non-web platforms to avoid import errors

class JsObject {
  JsObject(dynamic object, [List? args]);

  dynamic callMethod(String method, [List? args]) => null;
  dynamic operator [](String key) => null;
  void operator []=(String key, dynamic value) {}

  static JsObject jsify(Map<String, dynamic> map) => JsObject(null);
}

class JsContext {
  dynamic operator [](String key) => null;
  void operator []=(String key, dynamic value) {}
}

final context = JsContext();
