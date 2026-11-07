import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:store_screenshots/src/core/captions.dart';
import 'package:store_screenshots/src/core/devices.dart';
import 'package:store_screenshots/src/core/gallery.dart';
import 'package:store_screenshots/src/core/output.dart';
import 'package:store_screenshots/src/core/png.dart';

void main() {
  group('fastlane paths', () {
    test('App Store', () {
      expect(
        shotPath(device: kDevices['iphone_6_9']!, locale: 'ar', index: 0, screenId: 'home'),
        'ios/ar-SA/iphone_6_9_01_home.png',
      );
    });
    test('Google Play phone and tablets', () {
      expect(
        shotPath(device: kDevices['android_phone']!, locale: 'en', index: 2, screenId: 'cart'),
        'android/en-US/images/phoneScreenshots/03_cart.png',
      );
      expect(
        shotPath(device: kDevices['android_tablet_10']!, locale: 'ar', index: 0, screenId: 'a'),
        'android/ar/images/tenInchScreenshots/01_a.png',
      );
      expect(featureGraphicPath('pt_BR'), 'android/pt-BR/images/featureGraphic.png');
    });
    test('locale mapping and overrides', () {
      expect(storeLocale('de', Store.ios), 'de-DE');
      expect(storeLocale('zh', Store.ios), 'zh-Hans');
      expect(storeLocale('he', Store.android), 'iw-IL');
      expect(storeLocale('xx', Store.android), 'xx');
      expect(
        storeLocale('ar', Store.ios, {
          'ar': {'ios': 'ar'},
        }),
        'ar',
      );
    });
    test('RTL detection', () {
      expect(isRtl('ar'), isTrue);
      expect(isRtl('ar_EG'), isTrue);
      expect(isRtl('fa'), isTrue);
      expect(isRtl('en'), isFalse);
    });
  });

  group('captions', () {
    test('emphasis and line breaks', () {
      expect(parseCaption(r'Shop *everything*\nin one place'), const [
        CaptionSpan('Shop '),
        CaptionSpan('everything', emphasis: true),
        CaptionSpan('\nin one place'),
      ]);
      expect(plainCaption('A *b* c'), 'A b c');
    });
    test('ARB parsing skips metadata', () {
      final c = Captions.parse('en', '{"@@locale":"en","a":"Hi","@a":{"description":"x"}}');
      expect(c.values, {'a': 'Hi'});
    });
    test('missing file gives empty captions, language fallback works', () {
      final dir = Directory.systemTemp.createTempSync('ss');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/store_pt.arb').writeAsStringSync('{"k":"Olá"}');
      expect(Captions.load(dir.path, 'pt_BR')['k'], 'Olá');
      expect(Captions.load(dir.path, 'fr').values, isEmpty);
    });
  });

  group('png', () {
    test('writes a 24-bit RGB PNG (no alpha) with valid CRCs', () {
      const w = 3, h = 2;
      final rgba = Uint8List.fromList([
        255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, //
        0, 0, 0, 0, 255, 255, 255, 128, 10, 20, 30, 255,
      ]);
      final png = encodeRgbPng(rgba, w, h);
      final header = readPngHeader(png);
      expect(header.width, w);
      expect(header.height, h);
      expect(header.colorType, 2, reason: 'truecolor without alpha');
      // Every chunk CRC must match.
      var o = 8;
      while (o < png.length) {
        final len = ByteData.sublistView(png, o, o + 4).getUint32(0);
        final crc = ByteData.sublistView(png, o + 8 + len, o + 12 + len).getUint32(0);
        expect(crc32(png, o + 4, o + 8 + len), crc);
        o += 12 + len;
      }
      expect(o, png.length);
      // Decompress and check pixels (transparent → white background).
      final idatLen = ByteData.sublistView(png, 33, 37).getUint32(0);
      final raw = ZLibDecoder().convert(png.sublist(41, 41 + idatLen));
      expect(raw.length, (w * 3 + 1) * h);
      expect(raw.sublist(1, 4), [255, 0, 0]);
      // Row 2 uses the "up" filter: decode it.
      final row2 = [for (var i = 1; i < w * 3 + 1; i++) (raw[(w * 3 + 1) + i] + raw[i]) & 0xFF];
      expect(row2.sublist(0, 3), [255, 255, 255], reason: 'alpha 0 is composited on white');
      expect(row2.sublist(6, 9), [10, 20, 30]);
    });
    test('crc32 known value', () => expect(crc32('IEND'.codeUnits), 0xAE426082));
  });

  test('gallery lists every image', () {
    final html = buildGallery(
      appName: 'Shop <&>',
      took: const Duration(seconds: 3),
      shots: const [
        ShotRecord(
          path: 'ios/en-US/a.png',
          locale: 'en',
          device: 'iphone_6_9',
          screen: 'home',
          template: 'aurora',
          theme: 'light',
          width: 1320,
          height: 2868,
        ),
        ShotRecord(
          path: 'android/en-US/images/featureGraphic.png',
          locale: 'en',
          device: 'feature_graphic',
          screen: 'feature_graphic',
          template: 'aurora',
          theme: 'light',
          width: 1024,
          height: 500,
          kind: 'feature_graphic',
        ),
      ],
    );
    expect(html, contains('Shop &lt;&amp;&gt;'));
    expect(html, contains('src="ios/en-US/a.png"'));
    expect(html, contains('class="wide"'));
    expect(html, contains('2 images'));
  });
}
