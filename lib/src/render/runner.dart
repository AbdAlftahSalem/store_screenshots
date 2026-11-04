import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/captions.dart';
import '../core/catalog.dart';
import '../core/config.dart';
import '../core/devices.dart';
import '../core/gallery.dart';
import '../core/output.dart';
import '../core/png.dart';
import 'device_frame.dart';
import 'feature_graphic.dart';
import 'fonts.dart';
import 'templates.dart';

/// What is being captured right now. Read it from your app builder or fakes
/// when you need more than the locale (e.g. the screen id).
class ShotContext {
  /// Creates a context.
  const ShotContext({
    required this.locale,
    required this.device,
    required this.screen,
    required this.theme,
  });

  /// Locale code from the config, e.g. `ar`.
  final String locale;

  /// Store device.
  final DeviceSpec device;

  /// Screen being captured.
  final ScreenConfig screen;

  /// `light` or `dark`.
  final String theme;

  /// Locale as a Flutter [Locale].
  Locale get flutterLocale => toLocale(locale);

  /// Whether the locale is right to left.
  bool get isRtl => kRtlLanguages.contains(locale.split(RegExp('[_-]')).first);

  /// Whether the app should render dark.
  bool get isDark => theme == 'dark';
}

/// Static access to the shot being captured.
abstract final class StoreShots {
  static ShotContext? _current;

  /// The shot being captured, or null outside of a store_shots run.
  static ShotContext? get current => _current;

  /// Whether code runs inside a store_shots capture.
  static bool get isCapturing => _current != null;
}

/// Converts `pt_BR` / `pt-BR` to a [Locale].
Locale toLocale(String code) {
  final parts = code.split(RegExp('[_-]'));
  return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
}

/// Builds the overrides (fake data) for a locale.
typedef OverridesBuilder<T> = List<T> Function(String locale);

/// Builds the app from the overrides.
typedef AppBuilder<T> = Widget Function(List<T> overrides);

/// Runs before each capture, after the app settled (tap, scroll, …).
typedef BeforeShot = Future<void> Function(WidgetTester tester, ShotContext shot);

/// Declares the screenshot tests. Call it from `main()` of a test file:
///
/// ```dart
/// void main() => storeShots(
///   overrides: (locale) => [repo.overrideWithValue(FakeRepo(locale))],
///   app: (overrides) => ProviderScope(overrides: overrides, child: const MyApp()),
/// );
/// ```
///
/// [config] is the path of `store_shots.yaml` (relative to the project).
void storeShots<T>({
  required AppBuilder<T> app,
  OverridesBuilder<T>? overrides,
  String config = 'store_shots.yaml',
  BeforeShot? beforeShot,
}) {
  final StoreShotsConfig cfg;
  try {
    // `dart run store_shots --config other.yaml` passes its file through the environment.
    cfg = StoreShotsConfig.load(Platform.environment['STORE_SHOTS_CONFIG'] ?? config);
  } on ConfigException catch (e) {
    test('store_shots config', () => fail(e.toString()));
    return;
  }
  final run = _Run(cfg, _envFilter('STORE_SHOTS_LOCALES'), _envFilter('STORE_SHOTS_DEVICES'),
      _envFilter('STORE_SHOTS_TEMPLATES'), _envFilter('STORE_SHOTS_SCREENS'));

  setUpAll(() async {
    await loadStoreShotsFonts();
    run.prepareOutput();
  });
  tearDownAll(run.finish);

  for (final locale in run.locales) {
    final captions = Captions.load(cfg.captionsDir, locale);
    for (final device in run.devices) {
      for (final theme in cfg.themes) {
        testWidgets('store_shots · $locale · ${device.id} · $theme', (tester) async {
          final shots = await _capture(tester, run, cfg, device, locale, theme, captions, app, overrides, beforeShot);
          await _compose(tester, run, cfg, device, locale, theme, captions, shots);
        }, timeout: const Timeout(Duration(minutes: 20)));
      }
    }
  }
}

Set<String>? _envFilter(String name) {
  final v = Platform.environment[name];
  if (v == null || v.trim().isEmpty) return null;
  return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
}

class _Run {
  _Run(this.cfg, Set<String>? locales, Set<String>? devices, Set<String>? templates, Set<String>? screens)
    : locales = cfg.locales.where((l) => locales == null || locales.contains(l)).toList(),
      devices = cfg.devices.where((d) => devices == null || devices.contains(d.id)).toList(),
      templates = templates == null
          ? cfg.templates
          : [for (final t in templates) if (kTemplates.contains(t) || t == 'none') t],
      screenFilter = screens;

  final StoreShotsConfig cfg;
  final List<String> locales;
  final List<DeviceSpec> devices;
  final List<String> templates;
  final Set<String>? screenFilter;
  final records = <ShotRecord>[];
  final warnings = <String>[];
  final stopwatch = Stopwatch()..start();

  String get out => cfg.output;

  void prepareOutput() {
    // Only remove what store_shots writes; never the whole folder.
    for (final sub in ['ios', 'android', 'variants', 'raw']) {
      final d = Directory('$out/$sub');
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
    Directory(out).createSync(recursive: true);
  }

  void write(String relPath, Uint8List png, ShotRecord record) {
    final f = File('$out/$relPath');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(png);
    records.add(record);
  }

  void finish() {
    stopwatch.stop();
    if (records.isEmpty) return;
    File('$out/manifest.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'app_name': cfg.appName,
      'took_ms': stopwatch.elapsedMilliseconds,
      'screens': cfg.screens.length,
      'locales': locales,
      'devices': [for (final d in devices) d.id],
      'templates': templates,
      'warnings': warnings,
      'images': [for (final r in records) r.toJson()],
    }));
    File('$out/gallery.html').writeAsStringSync(
      buildGallery(appName: cfg.appName, shots: records, took: stopwatch.elapsed),
    );
    final store = records.where((r) => r.kind == 'screenshot' && !r.path.startsWith('variants/')).length;
    final fg = records.where((r) => r.kind == 'feature_graphic').length;
    final variants = records.where((r) => r.path.startsWith('variants/')).length;
    final screens = screenFilter == null ? cfg.screens.length : cfg.screens.where((s) => screenFilter!.contains(s.id)).length;
    // ignore: avoid_print
    String n(int n, String w) => '$n $w${n == 1 ? '' : 's'}';
    // ignore: avoid_print
    print('\n✔ store_shots: ${n(screens, 'screen')} × ${n(locales.length, 'locale')} × ${n(devices.length, 'device')} = '
        '$store screenshots${fg > 0 ? ' + $fg feature graphic${fg == 1 ? '' : 's'}' : ''}'
        '${variants > 0 ? ' + $variants variant images' : ''} '
        '(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s)\n  → $out/gallery.html');
    final counts = <String, int>{};
    for (final w in warnings) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    counts.forEach((w, n) {
      // ignore: avoid_print
      print('  ⚠ $w${n > 1 ? ' (×$n)' : ''}');
    });
  }
}

TargetPlatform? _platformFor(StoreShotsConfig cfg, DeviceSpec device) => switch (cfg.platform) {
  'ios' => TargetPlatform.iOS,
  'android' => TargetPlatform.android,
  'none' => null,
  _ => device.store == Store.ios ? TargetPlatform.iOS : TargetPlatform.android,
};

Future<List<ScreenShot>> _capture<T>(
  WidgetTester tester,
  _Run run,
  StoreShotsConfig cfg,
  DeviceSpec device,
  String locale,
  String theme,
  Captions captions,
  AppBuilder<T> app,
  OverridesBuilder<T>? overrides,
  BeforeShot? beforeShot,
) async {
  final raw = run.templates.length == 1 && run.templates.first == 'none';
  final size = device.appSize(framed: !raw);
  final dpr = device.pixelRatio;
  final view = tester.view;
  final dispatcher = tester.platformDispatcher;
  view.devicePixelRatio = dpr;
  view.physicalSize = Size(size.width * dpr, size.height * dpr);
  view.padding = FakeViewPadding(top: device.statusBarHeight * dpr, bottom: device.bottomInset * dpr);
  view.viewPadding = FakeViewPadding(top: device.statusBarHeight * dpr, bottom: device.bottomInset * dpr);
  dispatcher.localesTestValue = [toLocale(locale)];
  dispatcher.localeTestValue = toLocale(locale);
  dispatcher.platformBrightnessTestValue = theme == 'dark' ? Brightness.dark : Brightness.light;
  addTearDown(() {
    view.reset();
    dispatcher.clearAllTestValues();
  });

  final shots = <ScreenShot>[];
  debugDefaultTargetPlatformOverride = _platformFor(cfg, device);
  try {
    for (final screen in cfg.screens) {
      final ctx = ShotContext(locale: locale, device: device, screen: screen, theme: theme);
      StoreShots._current = ctx;
      dispatcher.defaultRouteNameTestValue = screen.route;
      final key = GlobalKey();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: KeyedSubtree(key: UniqueKey(), child: app(overrides?.call(locale) ?? <T>[])),
      ));
      await _settle(tester, cfg.waitMs);
      if (beforeShot != null) {
        await beforeShot(tester, ctx);
        await _settle(tester, cfg.waitMs);
      }
      final error = tester.takeException();
      if (error != null) {
        run.warnings.add('$locale/${device.id}/${screen.id}: ${error.toString().split('\n').first}');
      }

      Rect? highlight;
      final h = screen.highlight;
      if (h != null) {
        final finder = find.byKey(ValueKey<String>(h.key)).hitTestable();
        if (finder.evaluate().isEmpty) {
          run.warnings.add('${screen.id}: no visible widget with key ValueKey("${h.key}") to highlight '
              '(is it off screen on ${device.id}?).');
        } else {
          highlight = tester.getRect(finder.first);
        }
      }

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final captured = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: dpr);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        return (image, bytes!);
      });
      final (image, bytes) = captured!;
      shots.add(ScreenShot(
        image: image,
        logicalWidth: size.width,
        logicalHeight: size.height,
        darkTop: _isDark(bytes, image.width, image.height, 0, device.statusBarHeight * dpr),
        darkBottom: _isDark(bytes, image.width, image.height, image.height - 30 * dpr, image.height.toDouble()),
        highlight: highlight,
        highlightConfig: h,
        highlightLabel: h?.label == null ? null : captions[h!.label!],
      ));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  } finally {
    StoreShots._current = null;
    debugDefaultTargetPlatformOverride = null;
  }
  return shots;
}

bool _isDark(ByteData rgba, int width, int height, double fromY, double toY) {
  final y0 = fromY.clamp(0, height - 1).toInt();
  final y1 = toY.clamp(y0 + 1, height).toInt();
  var sum = 0.0;
  var n = 0;
  for (var y = y0; y < y1; y += 3) {
    for (var x = 0; x < width; x += 7) {
      final o = (y * width + x) * 4;
      sum += 0.2126 * rgba.getUint8(o) + 0.7152 * rgba.getUint8(o + 1) + 0.0722 * rgba.getUint8(o + 2);
      n++;
    }
  }
  return n > 0 && sum / n < 140;
}

Future<void> _settle(WidgetTester tester, int waitMs) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await _precacheImages(tester);
  for (var i = 0; i < 4; i++) {
    await tester.pump(Duration(milliseconds: waitMs ~/ 4 + 1));
  }
  try {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
  } on FlutterError {
    // An endless animation (e.g. a spinner). The frame we have is fine.
  }
  await _precacheImages(tester);
  await tester.pump();
}

Future<void> _precacheImages(WidgetTester tester) async {
  final targets = <(ImageProvider, Element)>[];
  for (final e in find.byType(Image, skipOffstage: false).evaluate()) {
    targets.add(((e.widget as Image).image, e));
  }
  for (final e in find.byType(DecoratedBox, skipOffstage: false).evaluate()) {
    final d = (e.widget as DecoratedBox).decoration;
    if (d is BoxDecoration && d.image != null) targets.add((d.image!.image, e));
  }
  for (final e in find.byType(Ink, skipOffstage: false).evaluate()) {
    final d = (e.widget as Ink).decoration;
    if (d is BoxDecoration && d.image != null) targets.add((d.image!.image, e));
  }
  if (targets.isEmpty) return;
  await tester.runAsync(() async {
    for (final (provider, element) in targets) {
      await precacheImage(provider, element, onError: (_, _) {});
    }
  });
  await tester.pump();
}

Future<void> _compose(
  WidgetTester tester,
  _Run run,
  StoreShotsConfig cfg,
  DeviceSpec device,
  String locale,
  String theme,
  Captions captions,
  List<ScreenShot> shots,
) async {
  final view = tester.view;
  view.devicePixelRatio = 1;
  view.padding = FakeViewPadding.zero;
  view.viewPadding = FakeViewPadding.zero;
  final rtl = isRtl(locale);
  final W = device.width.toDouble(), H = device.height.toDouble();
  final primaryTheme = theme == cfg.themes.first;

  for (final template in run.templates) {
    final primary = template == run.templates.first && primaryTheme;
    String pathFor(int i, ScreenConfig s) {
      final base = shotPath(device: device, locale: locale, index: i, screenId: s.id, localeOverrides: cfg.storeLocales);
      return primary ? base : '${variantPrefix(template, theme)}$base';
    }

    TemplateStyle styleFor(String id) => kTemplateStyles[id]!.withOverrides(
      colors: cfg.background == null ? null : [for (final c in cfg.background!.colors) Color(c)],
      accent: cfg.accent == null ? null : Color(cfg.accent!),
      caption: cfg.captionColor == null ? null : Color(cfg.captionColor!),
    );

    ShotScene sceneFor(int i, TemplateStyle style) {
      final frame = cfg.frameFor(device, lightFinish: style.lightFrame);
      final s = cfg.screens[i];
      final headline = captions[s.caption];
      if (headline == null && captions.values.isNotEmpty && template == run.templates.first) {
        run.warnings.add('missing caption "${s.caption}" in store_$locale.arb');
      }
      return ShotScene(
        style: style,
        device: device,
        frame: frame,
        config: cfg,
        shots: shots,
        index: i,
        headline: headline ?? '',
        subtitle: captions[s.subtitle ?? '${s.caption}_subtitle'] ?? '',
        rtl: rtl,
      );
    }

    bool wanted(ScreenConfig s) => run.screenFilter == null || run.screenFilter!.contains(s.id);

    if (template == 'none') {
      for (var i = 0; i < cfg.screens.length; i++) {
        if (!wanted(cfg.screens[i])) continue;
        final png = await _render(tester, Size(W, H), SizedBox(
          width: W,
          height: H,
          child: DeviceFrame(
            shot: shots[i],
            device: device,
            frame: cfg.frameFor(device),
            statusBar: cfg.statusBar,
            framed: false,
            rounded: false,
            shadow: false,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ));
        run.write(pathFor(i, cfg.screens[i]), png, _rec(pathFor(i, cfg.screens[i]), locale, device, cfg.screens[i].id, template, theme));
      }
      continue;
    }

    final style = styleFor(template);
    if (style.layout == TemplateLayout.panorama && cfg.screens.length > 1) {
      final scenes = [for (var i = 0; i < cfg.screens.length; i++) sceneFor(i, style)];
      final n = scenes.length;
      final wide = await _renderImage(tester, Size(W * n, H), PanoramaComposer(scenes: scenes, panel: Size(W, H)));
      for (var i = 0; i < n; i++) {
        if (!wanted(cfg.screens[i])) continue;
        final slot = rtl ? n - 1 - i : i;
        final png = await _slice(tester, wide, Rect.fromLTWH(slot * W, 0, W, H));
        run.write(pathFor(i, cfg.screens[i]), png, _rec(pathFor(i, cfg.screens[i]), locale, device, cfg.screens[i].id, template, theme));
      }
    } else {
      for (var i = 0; i < cfg.screens.length; i++) {
        final s = cfg.screens[i];
        if (!wanted(s)) continue;
        final own = primary && s.template != null ? styleFor(s.template!) : style;
        final png = await _render(tester, Size(W, H), ShotComposer(scene: sceneFor(i, own), size: Size(W, H)));
        run.write(pathFor(i, s), png, _rec(pathFor(i, s), locale, device, s.id, own.id, theme));
      }
    }

    // Feature Graphic: once per locale, from the first Android device (or
    // the first device when the run has no Android device).
    final fgDevice = run.devices.firstWhere((d) => d.store == Store.android && !d.tablet, orElse: () => run.devices.first);
    if (cfg.featureGraphic && primary && device.id == fgDevice.id && template != 'none') {
      final size = Size(kFeatureGraphicSize.width.toDouble(), kFeatureGraphicSize.height.toDouble());
      final png = await _render(tester, size, FeatureGraphicComposer(
        scene: sceneFor(0, style),
        appName: captions['app_name'] ?? cfg.appName,
        tagline: captions[cfg.tagline] ?? '',
        size: size,
      ));
      final p = featureGraphicPath(locale, cfg.storeLocales);
      run.write(p, png, ShotRecord(
        path: p,
        locale: locale,
        device: 'feature_graphic',
        screen: 'feature_graphic',
        template: template,
        theme: theme,
        width: kFeatureGraphicSize.width,
        height: kFeatureGraphicSize.height,
        kind: 'feature_graphic',
      ));
    }
  }
  await tester.pumpWidget(const SizedBox.shrink());
}

ShotRecord _rec(String path, String locale, DeviceSpec d, String screen, String template, String theme) => ShotRecord(
  path: path,
  locale: locale,
  device: d.id,
  screen: screen,
  template: template,
  theme: theme,
  width: d.width,
  height: d.height,
);

Future<ui.Image> _renderImage(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  final key = GlobalKey();
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(key: key, child: SizedBox(width: size.width, height: size.height, child: child)),
    ),
  ));
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
}

Future<Uint8List> _render(WidgetTester tester, Size size, Widget child) async {
  final image = await _renderImage(tester, size, child);
  return _encode(tester, image);
}

Future<Uint8List> _encode(WidgetTester tester, ui.Image image) async {
  final bytes = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
  return encodeRgbPng(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), image.width, image.height);
}

Future<Uint8List> _slice(WidgetTester tester, ui.Image wide, Rect rect) async {
  final image = (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(wide, rect, Offset.zero & rect.size, Paint()..filterQuality = FilterQuality.none);
    return recorder.endRecording().toImage(rect.width.round(), rect.height.round());
  }))!;
  return _encode(tester, image);
}
