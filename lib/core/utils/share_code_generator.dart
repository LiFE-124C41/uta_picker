import 'dart:convert';
import 'dart:typed_data';

/// YouTube共有コードの生成と解析を行うクラス。
///
/// バイナリフォーマット:
/// [Version(1byte)][VideoID(11bytes)][Start(2bytes)][End(2bytes)][Title(Variable)]
/// 全体をBase64URLエンコードする。
class ShareCodeGenerator {
  static const int _version = 1;

  /// 動画情報をシェアコードに変換します。
  ///
  /// [videoId]: YouTube動画ID (11文字固定)
  /// [startSec]: 開始秒数 (nullまたは0の場合は0として記録)
  /// [endSec]: 終了秒数 (nullまたは0の場合は動画の最後までとして0として記録)
  /// [title]: 楽曲タイトル
  static String encode({
    required String videoId,
    int? startSec,
    int? endSec,
    String? title,
  }) {
    if (videoId.length != 11) {
      throw const FormatException('Video ID must be 11 characters long.');
    }

    final buffer = BytesBuilder();

    // 1. Version
    buffer.addByte(_version);

    // 2. Video ID (ASCII)
    // YouTube IDは通常ASCII文字のみ (Base64url characters)
    buffer.add(ascii.encode(videoId));

    // 3. Start Time (UInt16BE)
    final start = startSec ?? 0;
    if (start < 0 || start > 65535) {
      // 範囲外の場合は0 (最初から) にするか、clampするか。一旦clamp。
      buffer.addByte((start.clamp(0, 65535) >> 8) & 0xFF);
      buffer.addByte(start.clamp(0, 65535) & 0xFF);
    } else {
      buffer.addByte((start >> 8) & 0xFF);
      buffer.addByte(start & 0xFF);
    }

    // 4. End Time (UInt16BE)
    final end = endSec ?? 0;
    if (end < 0 || end > 65535) {
      buffer.addByte((end.clamp(0, 65535) >> 8) & 0xFF);
      buffer.addByte(end.clamp(0, 65535) & 0xFF);
    } else {
      buffer.addByte((end >> 8) & 0xFF);
      buffer.addByte(end & 0xFF);
    }

    // 5. Title (UTF-8)
    if (title != null && title.isNotEmpty) {
      buffer.add(utf8.encode(title));
    }

    // Base64Url encode without padding for shorter URL
    return base64Url.encode(buffer.toBytes()).replaceAll('=', '');
  }

  /// シェアコードを解析して動画情報を返します。
  ///
  /// 戻り値:
  /// {
  ///   'videoId': String,
  ///   'startSec': int?, // null if 0
  ///   'endSec': int?, // null if 0
  ///   'title': String?,
  /// }
  static Map<String, dynamic> decode(String code) {
    if (code.isEmpty) {
      throw const FormatException('Code is empty.');
    }

    Uint8List bytes;
    try {
      // パディングを復元してデコード
      final padded = _addPadding(code);
      bytes = base64Url.decode(padded);
    } catch (e) {
      throw const FormatException('Invalid Base64 string.');
    }

    if (bytes.isEmpty) {
      throw const FormatException('Empty data.');
    }

    final reader = _ByteReader(bytes);

    // 1. Version
    final version = reader.readByte();
    if (version != _version) {
      throw FormatException('Unsupported version: $version');
    }

    // 2. Video ID
    // Video IDは11バイト確認
    if (!reader.checkAvailable(11)) {
      throw const FormatException('Invalid data length (missing videoId).');
    }
    final videoId = reader.readAscii(11);

    // 3. Start Time
    if (!reader.checkAvailable(2)) {
      throw const FormatException('Invalid data length (missing times).');
    }
    final startRaw = reader.readUint16();
    // 0の場合はnull (指定なし)
    final startSec = startRaw == 0 ? null : startRaw;

    // 4. End Time
    // Start読んだので残り確認不要(上で2+2チェックしてないなら必要だが、Uint16でチェック入る)
    final endRaw = reader.readUint16();
    final endSec = endRaw == 0 ? null : endRaw;

    // 5. Title
    String? title;
    if (reader.hasMore) {
      title = reader.readUtf8Remaining();
    }

    return {
      'videoId': videoId,
      'startSec': startSec,
      'endSec': endSec,
      'title': title,
    };
  }

  static String _addPadding(String input) {
    int pad = input.length % 4;
    if (pad > 0) {
      return input.padRight(input.length + (4 - pad), '=');
    }
    return input;
  }
}

class _ByteReader {
  final Uint8List _bytes;
  int _offset = 0;

  _ByteReader(this._bytes);

  bool get hasMore => _offset < _bytes.length;

  bool checkAvailable(int length) {
    return _offset + length <= _bytes.length;
  }

  int readByte() {
    if (_offset >= _bytes.length) throw RangeError('End of stream');
    return _bytes[_offset++];
  }

  String readAscii(int length) {
    if (_offset + length > _bytes.length) throw RangeError('End of stream');
    final str = ascii.decode(_bytes.sublist(_offset, _offset + length));
    _offset += length;
    return str;
  }

  int readUint16() {
    if (_offset + 2 > _bytes.length) throw RangeError('End of stream');
    final val = (_bytes[_offset] << 8) | _bytes[_offset + 1];
    _offset += 2;
    return val;
  }

  String readUtf8Remaining() {
    final str = utf8.decode(_bytes.sublist(_offset));
    _offset = _bytes.length;
    return str;
  }
}
