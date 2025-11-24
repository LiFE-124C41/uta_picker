// lib/platform/stubs/html_stub.dart
// Stub file for non-web platforms
// This file is used when compiling for non-web platforms to avoid import errors

class Document {
  static Document? get document => null;
  Element? get head => null;
  Element? get body => null;
  Element? getElementById(String id) => null;
  Element? querySelector(String selector) => null;
  List<Element> querySelectorAll(String selector) => [];
}

class Element {
  void append(dynamic child) {}
  void remove() {}
  List<Element> get children => [];
  void clear() {}
  List<Element> querySelectorAll(String selector) => [];
}

class ScriptElement extends Element {
  String? src;
  bool? async;
}

class DivElement extends Element {
  String? id;
  Style get style => Style();
}

class IFrameElement extends Element {
  String? src;
  Style get style => Style();
}

class Style {
  String? border;
  String? width;
  String? height;
  String? pointerEvents;
}

class Blob {
  Blob(List<dynamic> data, [String? type]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement extends Element {
  String? href;
  AnchorElement({this.href});
  void click() {}
  void setAttribute(String name, String value) {}
}

class Location {
  void reload() {}
}

class Window {
  Location get location => Location();
}

final document = Document();
final window = Window();
