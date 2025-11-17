// lib/core/utils/csv_export.dart
class CsvExport {
  static String escape(String s) {
    if (s.contains(',') || s.contains('"')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

