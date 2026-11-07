import 'package:flutter_test/flutter_test.dart';
import 'package:store_screenshots/src/core/catalog.dart';
import 'package:store_screenshots/src/core/devices.dart';
import 'package:store_screenshots/src/core/geometry.dart';

void main() {
  test('official store sizes (Nov 2026)', () {
    final sizes = {for (final d in kDevices.values) d.id: (d.width, d.height)};
    expect(sizes, {
      'iphone_6_9': (1320, 2868),
      'iphone_6_5': (1284, 2778),
      'iphone_6_3': (1206, 2622),
      'ipad_13': (2064, 2752),
      'android_phone': (1080, 1920),
      'android_tablet_7': (1440, 2560),
      'android_tablet_10': (2160, 3840),
    });
  });

  test('iOS screens render at exactly the store size', () {
    for (final d in kDevices.values.where((d) => d.store == Store.ios)) {
      expect(d.screenWidth * d.pixelRatio, d.width, reason: d.id);
      expect(d.screenHeight * d.pixelRatio, d.height, reason: d.id);
    }
  });

  test('every Play size follows the Play rules', () {
    for (final d in kDevices.values.where((d) => d.store == Store.android)) {
      expect(isValidPlaySize(d.width, d.height), isTrue, reason: d.id);
      // Recommended 9:16 portrait.
      expect(d.width / d.height, closeTo(9 / 16, 0.001), reason: d.id);
    }
    expect(isValidPlaySize(300, 500), isFalse);
    expect(isValidPlaySize(1000, 2100), isFalse);
    expect(isValidPlaySize(4000, 2000), isFalse);
  });

  test('frameless app size fills the output exactly', () {
    final d = kDevices['android_phone']!;
    final s = d.appSize(framed: false);
    expect(s.width * d.pixelRatio, closeTo(1080, 1e-9));
    expect(s.height * d.pixelRatio, closeTo(1920, 1e-9));
    expect(d.appSize(framed: true).width, d.screenWidth);
  });

  test('every device default frame exists and every frame has 2+ colors', () {
    for (final d in kDevices.values) {
      expect(kFrameModels[d.defaultFrame], isNotNull, reason: d.id);
    }
    expect(kFrameModels.values.where((m) => m.shape == FrameShape.island), hasLength(3));
    expect(kFrameModels.values.where((m) => m.shape == FrameShape.punchHole), hasLength(3));
    for (final m in kFrameModels.values) {
      expect(m.finishes.length, greaterThanOrEqualTo(2), reason: m.id);
    }
  });

  group('geometry', () {
    test('frame wraps the screen with even bezels', () {
      final g = frameGeometry(kFrameModels['iphone_17_pro']!, 440, 956);
      final bezel = 0.040 * 440;
      expect(g.outerWidth, closeTo(440 + bezel * 2, 1e-9));
      expect(g.outerHeight, closeTo(956 + bezel * 2, 1e-9));
      expect(g.screen.left, closeTo(bezel, 1e-9));
      expect(g.screen.width, 440);
      expect(g.screenRadius, lessThan(g.outerRadius));
      expect(g.bezel + g.rail, closeTo(bezel, 1e-9));
    });

    test('fitAspect keeps the ratio and stays inside', () {
      final f = fitAspect(0.5, 400, 600);
      expect(f.width, 300);
      expect(f.height, 600);
      final g = fitAspect(2, 400, 600);
      expect(g.width, 400);
      expect(g.height, 200);
    });

    test('cover scale and panorama offsets', () {
      expect(coverScale(100, 200, 300, 300), 3);
      expect(panoramaOffsets(3, 1320), [0, 1320, 2640]);
    });
  });
}
