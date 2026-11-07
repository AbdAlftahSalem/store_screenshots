import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

bool _loaded = false;

/// Families that apps get by default on each platform. In `flutter test`
/// none of them exist (you get the box-glyph test font), so we load real
/// fonts under these names: Latin + Arabic in one font, so Arabic text
/// shapes correctly even when the app never picked an Arabic font.
const List<String> _systemFamilies = [
  'Roboto',
  'CupertinoSystemText',
  'CupertinoSystemDisplay',
  '.SF Pro Text',
  '.SF Pro Display',
  '.SF UI Text',
  '.SF UI Display',
  '.AppleSystemUIFont',
  'Segoe UI',
  'Ubuntu',
];

/// Loads every font the screenshots need: the app's own fonts (from
/// `FontManifest.json`), real system-font stand-ins, Material Icons and
/// the caption fonts. Safe to call more than once.
Future<void> loadStoreShotsFonts() async {
  if (_loaded) return;
  _loaded = true;
  final appFamilies = <String>{};

  // 1. The app's fonts (pubspec `fonts:` of the app and its packages).
  try {
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<Object?>;
    for (final entry in manifest.cast<Map<String, Object?>>()) {
      final family = entry['family']! as String;
      final loader = FontLoader(family);
      for (final font in (entry['fonts']! as List<Object?>).cast<Map<String, Object?>>()) {
        loader.addFont(rootBundle.load(font['asset']! as String));
      }
      await loader.load();
      appFamilies.add(family);
    }
  } on Object {
    // No FontManifest: the app declares no fonts. Fine.
  }

  final fontsDir = _packageFontsDir();
  Future<void> loadFiles(String family, List<String> files) async {
    final loader = FontLoader(family);
    var any = false;
    for (final f in files) {
      final file = File('$fontsDir/$f');
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      any = true;
    }
    if (any) await loader.load();
  }

  const sans = ['StoreShotsSans-Regular.ttf', 'StoreShotsSans-Medium.ttf', 'StoreShotsSans-Bold.ttf'];
  await loadFiles('StoreShotsSans', sans);
  for (final family in _systemFamilies) {
    if (!appFamilies.contains(family)) await loadFiles(family, sans);
  }
  await loadFiles('StoreShotsDisplay', const [
    'Poppins-Medium.ttf',
    'Poppins-SemiBold.ttf',
    'Poppins-Bold.ttf',
    'Poppins-ExtraBold.ttf',
  ]);
  await loadFiles('StoreShotsArabic', const [
    'IBMPlexSansArabic-Medium.ttf',
    'IBMPlexSansArabic-SemiBold.ttf',
    'IBMPlexSansArabic-Bold.ttf',
  ]);

  // Material Icons ship with the Flutter SDK; load them if the app's
  // manifest did not (e.g. `uses-material-design: false` in a package).
  if (!appFamilies.contains('MaterialIcons')) {
    final root = flutterRoot();
    final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (root != null && icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  }
}

/// The Flutter SDK folder, from `FLUTTER_ROOT` or the test runner's path.
String? flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  final exe = Platform.resolvedExecutable.replaceAll('\\', '/');
  final i = exe.indexOf('/bin/cache/');
  return i > 0 ? exe.substring(0, i) : null;
}

/// Finds `<store_screenshots package>/fonts` through `.dart_tool/package_config.json`.
String _packageFontsDir() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final cfg = File('${dir.path}/.dart_tool/package_config.json');
    if (cfg.existsSync()) {
      final json = jsonDecode(cfg.readAsStringSync()) as Map<String, Object?>;
      for (final p in (json['packages']! as List<Object?>).cast<Map<String, Object?>>()) {
        if (p['name'] == 'store_screenshots') {
          final root = cfg.uri.resolve(p['rootUri']! as String);
          final path = root.toFilePath();
          return '${path.endsWith(Platform.pathSeparator) ? path.substring(0, path.length - 1) : path}/fonts';
        }
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return 'fonts';
}
