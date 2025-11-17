// lib/core/utils/csv_import.dart
class CsvImport {
  /// CSV行をパースしてフィールドのリストを返す
  /// ダブルクォートで囲まれた値やエスケープされたダブルクォートを正しく処理
  static List<String> parseLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // エスケープされたダブルクォート ("")
          buffer.write('"');
          i += 2;
        } else {
          // クォートの開始/終了
          inQuotes = !inQuotes;
          i++;
        }
      } else if (char == ',' && !inQuotes) {
        // フィールドの区切り
        fields.add(buffer.toString());
        buffer.clear();
        i++;
      } else {
        buffer.write(char);
        i++;
      }
    }

    // 最後のフィールドを追加
    fields.add(buffer.toString());

    return fields;
  }

  /// CSV文字列をパースしてPlaylistItemのリストに変換
  /// ヘッダー行は自動的にスキップされる
  static List<Map<String, String>> parseCsv(String csvContent) {
    final lines = csvContent.split('\n');
    final result = <Map<String, String>>[];

    if (lines.isEmpty) return result;

    // ヘッダー行を取得
    final headerLine = lines[0].trim();
    if (headerLine.isEmpty) return result;

    final headers = parseLine(headerLine);
    final expectedHeaders = ['video_title', 'song_title', 'video_id', 'start_sec', 'end_sec', 'link'];

    // ヘッダーのインデックスをマッピング
    final headerIndices = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i].trim();
      if (expectedHeaders.contains(header)) {
        headerIndices[header] = i;
      }
    }

    // 必須フィールドの確認
    if (!headerIndices.containsKey('video_id') ||
        !headerIndices.containsKey('start_sec') ||
        !headerIndices.containsKey('end_sec')) {
      throw FormatException('CSVファイルに必須フィールド（video_id, start_sec, end_sec）が含まれていません');
    }

    // データ行を処理
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = parseLine(line);
      if (fields.length != headers.length) {
        // フィールド数が一致しない場合はスキップ（警告は出さない）
        continue;
      }

      final row = <String, String>{};
      headerIndices.forEach((header, index) {
        if (index < fields.length) {
          row[header] = fields[index].trim();
        }
      });

      // 必須フィールドが空でないことを確認
      if (row['video_id']?.isNotEmpty == true &&
          row['start_sec']?.isNotEmpty == true &&
          row['end_sec']?.isNotEmpty == true) {
        result.add(row);
      }
    }

    return result;
  }
}

