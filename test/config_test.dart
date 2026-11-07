import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:store_screenshots/src/core/catalog.dart';
import 'package:store_screenshots/src/core/config.dart';
import 'package:store_screenshots/src/core/devices.dart';

void main() {
  group('defaults', () {
    test('an empty file gives a working config', () {
      final c = StoreShotsConfig.parse('', projectDir: '/nonexistent');
      expect(c.devices.map((d) => d.id), kDefaultDevices);
      expect(c.locales, ['en']);
      expect(c.template, 'aurora');
      expect(c.themes, ['light']);
      expect(c.frame, isTrue);
      expect(c.output, 'build/store_shots');
      expect(c.screens.single.route, '/');
      expect(c.statusBar.time, '9:41');
      expect(c.statusBar.battery, 100);
      expect(c.featureGraphic, isTrue);
    });

    test('locales come from store_<locale>.arb files, English first', () {
      final dir = Directory.systemTemp.createTempSync('ss');
      addTearDown(() => dir.deleteSync(recursive: true));
      Directory('${dir.path}/lib/l10n').createSync(recursive: true);
      for (final l in ['ar', 'de', 'en']) {
        File('${dir.path}/lib/l10n/store_$l.arb').writeAsStringSync('{}');
      }
      final c = StoreShotsConfig.parse('screens: [home]', projectDir: dir.path);
      expect(c.locales, ['en', 'ar', 'de']);
      expect(c.captionsDir, 'lib/l10n');
    });

    test('app name falls back to the pubspec name', () {
      final dir = Directory.systemTemp.createTempSync('ss');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/pubspec.yaml').writeAsStringSync('name: my_cool_shop\n');
      expect(StoreShotsConfig.parse('', projectDir: dir.path).appName, 'My Cool Shop');
    });
  });

  group('parsing', () {
    test('full example', () {
      final c = StoreShotsConfig.parse('''
app_name: Basket
locales: [en, ar]
devices: [iphone_6_9, ipad_13, android_phone]
templates: [glass, bold]
theme: [light, dark]
frames:
  ios: iphone_17_pro/desert_titanium
  android: { model: galaxy, color: icy_blue }
background: { gradient: ["#4F46E5", "#7C3AED"] }
accent: "#FF0066"
status_bar: { time: "10:09", battery: 80 }
screens:
  - id: home
    route: /
  - id: product
    route: /product/1
    caption: caption_product
    highlight: { key: buy, style: arrow, label: hl_buy }
  - cart
''', projectDir: '/nonexistent');
      expect(c.appName, 'Basket');
      expect(c.locales, ['en', 'ar']);
      expect(c.devices.map((d) => d.id), ['iphone_6_9', 'ipad_13', 'android_phone']);
      expect(c.templates, ['glass', 'bold']);
      expect(c.themes, ['light', 'dark']);
      expect(c.frames[Store.ios].toString(), 'iphone_17_pro/desert_titanium');
      expect(c.frames[Store.android].toString(), 'galaxy/icy_blue');
      expect(c.background!.colors, [0xFF4F46E5, 0xFF7C3AED]);
      expect(c.accent, 0xFFFF0066);
      expect(c.statusBar.time, '10:09');
      expect(c.statusBar.battery, 80);
      expect(c.screens.map((s) => s.id), ['home', 'product', 'cart']);
      expect(c.screens[0].caption, 'caption_home');
      expect(c.screens[1].highlight!.key, 'buy');
      expect(c.screens[1].highlight!.style, HighlightStyle.arrow);
      expect(c.screens[1].highlight!.label, 'hl_buy');
      expect(c.screens[2].route, '/cart');
      expect(c.shotCount, 3 * 2 * 3);
    });

    test('template: all expands to every template', () {
      expect(StoreShotsConfig.parse('template: all', projectDir: '/x').templates, kTemplates);
      expect(kTemplates, hasLength(10));
    });

    test('the iPad gets the iPad frame even when an iPhone frame is chosen', () {
      final c = StoreShotsConfig.parse('frames: {ios: iphone_air}', projectDir: '/x');
      expect(c.frameFor(kDevices['iphone_6_9']!).model.id, 'iphone_air');
      expect(c.frameFor(kDevices['ipad_13']!).model.id, 'ipad_pro');
    });

    test('default finish follows the template tone', () {
      final c = StoreShotsConfig.parse('', projectDir: '/x');
      final dark = c.frameFor(kDevices['iphone_6_9']!);
      final light = c.frameFor(kDevices['iphone_6_9']!, lightFinish: true);
      expect(dark.finish.name, 'deep_blue');
      expect(light.finish.name, 'silver');
    });

    test('colors', () {
      expect(parseColor('#fff', 'x'), 0xFFFFFFFF);
      expect(parseColor('#4F46E5', 'x'), 0xFF4F46E5);
      expect(parseColor('#804F46E5', 'x'), 0x804F46E5);
      expect(parseColor('0xFF000000', 'x'), 0xFF000000);
      expect(() => parseColor('blue', 'x'), throwsA(isA<ConfigException>()));
    });
  });

  group('clear errors', () {
    String err(String yaml) {
      try {
        StoreShotsConfig.parse(yaml, projectDir: '/x');
      } on ConfigException catch (e) {
        return e.message;
      }
      fail('expected a ConfigException');
    }

    test('typo in a device suggests the right one', () {
      expect(err('devices: [iphone_69]'), contains('Did you mean "iphone_6_9"'));
    });
    test('typo in an option name', () {
      expect(err('templte: aurora'), contains('Did you mean "template"'));
    });
    test('unknown template', () => expect(err('template: auroa'), contains('aurora')));
    test('unknown frame color lists the colors', () {
      expect(err('frame: iphone_17_pro/pink'), contains('cosmic_orange'));
    });
    test('duplicate screen ids', () => expect(err('screens: [home, home]'), contains('twice')));
    test('route must start with /', () {
      expect(err('screens:\n  - id: a\n    route: cart'), contains('must start with "/"'));
    });
    test('too many screens for Google Play', () {
      final screens = List.generate(9, (i) => 's$i').join(', ');
      expect(err('screens: [$screens]'), contains('at most 8'));
    });
    test('battery range', () => expect(err('status_bar: {battery: 140}'), contains('0 to 100')));
    test('bad theme', () => expect(err('theme: sepia'), contains('light, dark')));
    test('bad yaml', () => expect(err('screens: [home'), contains('invalid YAML')));
  });

  test('levenshtein', () {
    expect(levenshtein('kitten', 'sitting'), 3);
    expect(levenshtein('', 'abc'), 3);
    expect(levenshtein('same', 'same'), 0);
  });
}
