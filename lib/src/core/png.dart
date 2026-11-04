import 'dart:io';
import 'dart:typed_data';

final Uint32List _crcTable = () {
  final t = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  return t;
}();

/// CRC-32 as used by PNG chunks.
int crc32(List<int> bytes, [int start = 0, int? end]) {
  var c = 0xFFFFFFFF;
  for (var i = start; i < (end ?? bytes.length); i++) {
    c = _crcTable[(c ^ bytes[i]) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Encodes RGBA pixels as a 24-bit RGB PNG (no alpha channel).
///
/// Both stores reject screenshots with an alpha channel, so transparent
/// pixels are composited over [background] (0xRRGGBB, white by default).
Uint8List encodeRgbPng(Uint8List rgba, int width, int height, {int background = 0xFFFFFF, int level = 6}) {
  final stride = width * 3 + 1;
  final raw = Uint8List(stride * height);
  final br = (background >> 16) & 0xFF, bgc = (background >> 8) & 0xFF, bb = background & 0xFF;
  var src = 0;
  for (var y = 0; y < height; y++) {
    var o = y * stride;
    raw[o++] = 0; // filter: none (filled below with "up" when it helps)
    for (var x = 0; x < width; x++) {
      final a = rgba[src + 3];
      if (a == 255) {
        raw[o] = rgba[src];
        raw[o + 1] = rgba[src + 1];
        raw[o + 2] = rgba[src + 2];
      } else {
        // Pixels from Flutter are premultiplied-free RGBA (straight alpha).
        raw[o] = (rgba[src] * a + br * (255 - a)) ~/ 255;
        raw[o + 1] = (rgba[src + 1] * a + bgc * (255 - a)) ~/ 255;
        raw[o + 2] = (rgba[src + 2] * a + bb * (255 - a)) ~/ 255;
      }
      o += 3;
      src += 4;
    }
  }
  // "Up" filter, applied bottom-up so we can do it in place.
  for (var y = height - 1; y >= 1; y--) {
    final o = y * stride;
    final p = (y - 1) * stride;
    raw[o] = 2;
    for (var i = 1; i < stride; i++) {
      raw[o + i] = (raw[o + i] - raw[p + i]) & 0xFF;
    }
  }
  final idat = ZLibEncoder(level: level).convert(raw);
  final out = BytesBuilder(copy: false)..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // color type: truecolor RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _chunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(out, 'IDAT', idat);
  _chunk(out, 'IEND', const []);
  return out.toBytes();
}

void _chunk(BytesBuilder out, String type, List<int> data) {
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  final typed = Uint8List(4 + data.length)
    ..setAll(0, type.codeUnits)
    ..setAll(4, data);
  out.add(typed);
  final crc = ByteData(4)..setUint32(0, crc32(typed));
  out.add(crc.buffer.asUint8List());
}

/// Reads width, height and color type from a PNG header.
({int width, int height, int colorType}) readPngHeader(List<int> bytes) {
  final d = ByteData.sublistView(Uint8List.fromList(bytes.sublist(0, 26)));
  return (width: d.getUint32(16), height: d.getUint32(20), colorType: d.getUint8(25));
}
