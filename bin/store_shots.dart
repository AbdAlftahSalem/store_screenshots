import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:store_shots/src/core/catalog.dart';
import 'package:store_shots/src/core/config.dart';
import 'package:store_shots/src/core/devices.dart';

const _testFile = 'test/store_shots_test.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('config', abbr: 'c', defaultsTo: 'store_shots.yaml', help: 'Config file.')
    ..addOption('test', abbr: 't', defaultsTo: _testFile, help: 'Test file that calls storeShots().')
    ..addOption('locales', abbr: 'l', help: 'Only these locales, e.g. en,ar.')
    ..addOption('devices', abbr: 'd', help: 'Only these devices, e.g. iphone_6_9.')
    ..addOption('template', help: 'Use these templates instead of the config (comma separated, or "all").')
    ..addOption('screens', abbr: 's', help: 'Only these screen ids.')
    ..addFlag('open', abbr: 'o', negatable: false, help: 'Open gallery.html when done.')
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Show the full flutter test output.')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    _fail('${e.message}\n\n${_usage(parser)}');
  }
  if (args['help'] as bool) {
    stdout.writeln(_usage(parser));
    return;
  }
  final command = args.rest.isEmpty ? 'run' : args.rest.first;
  switch (command) {
    case 'run':
      await _run(args);
    case 'init':
      _init(args);
    case 'templates':
      stdout.writeln('Templates (template: <name> in store_shots.yaml, or template: all):\n');
      for (final t in kTemplates) {
        stdout.writeln('  ${t.padRight(11)} ${kTemplateDescriptions[t]}');
      }
      stdout.writeln('  ${'none'.padRight(11)} Raw app screenshot at the exact store size, no frame or caption');
    case 'devices':
      stdout.writeln('Devices (devices: [...] in store_shots.yaml):\n');
      for (final d in kDevices.values) {
        stdout.writeln('  ${d.id.padRight(18)} ${d.label.padRight(20)} ${d.width}×${d.height}  '
            '${d.store == Store.ios ? 'App Store' : 'Google Play'}');
      }
    case 'frames':
      stdout.writeln('Frames (frames: {ios: model/color, android: model/color}):\n');
      for (final m in kFrameModels.values) {
        stdout.writeln('  ${m.id.padRight(16)} ${m.finishes.map((f) => f.name).join(', ')}');
      }
    default:
      _fail('Unknown command "$command".\n\n${_usage(parser)}');
  }
}

String _usage(ArgParser p) => '''
store_shots: App Store & Google Play screenshots from flutter test

Usage:
  dart run store_shots            Generate everything in store_shots.yaml
  dart run store_shots init       Create store_shots.yaml, the test file and a caption file
  dart run store_shots templates  List templates
  dart run store_shots devices    List devices and their store sizes
  dart run store_shots frames     List device frames and colors

Options:
${p.usage}''';

Never _fail(String message) {
  stderr.writeln('✘ $message');
  exit(64);
}

Future<void> _run(ArgResults args) async {
  final configPath = args['config'] as String;
  final StoreShotsConfig cfg;
  try {
    cfg = StoreShotsConfig.load(configPath);
  } on ConfigException catch (e) {
    _fail('$e');
  }
  final testPath = args['test'] as String;
  if (!File(testPath).existsSync()) {
    _fail('$testPath not found. Run `dart run store_shots init` to create it, or pass --test <file>.');
  }
  final env = <String, String>{};
  void filter(String opt, String name) {
    final v = args[opt] as String?;
    if (v != null) env[name] = v == 'all' && opt == 'template' ? kTemplates.join(',') : v;
  }

  filter('locales', 'STORE_SHOTS_LOCALES');
  filter('devices', 'STORE_SHOTS_DEVICES');
  filter('template', 'STORE_SHOTS_TEMPLATES');
  filter('screens', 'STORE_SHOTS_SCREENS');

  final devices = cfg.devices.map((d) => d.id).join(', ');
  stdout.writeln('▶ store_shots: ${_n(cfg.screens.length, 'screen')} × ${_n(cfg.locales.length, 'locale')} '
      '(${cfg.locales.join(', ')}) × ${_n(cfg.devices.length, 'device')} ($devices) · '
      'template: ${env['STORE_SHOTS_TEMPLATES'] ?? cfg.templates.join(', ')}');
  final sw = Stopwatch()..start();
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final process = await Process.start(flutter, ['test', testPath, '--reporter', 'expanded', '--no-pub'],
      environment: env, runInShell: Platform.isWindows);
  final verbose = args['verbose'] as bool;
  var summary = <String>[];
  var inSummary = false;
  final failures = <String>[];
  final done = <String>{};
  final out = process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (verbose) {
      stdout.writeln(line);
      return;
    }
    final m = RegExp(r'store_shots · (\S+) · (\S+) · (\S+)').firstMatch(line);
    if (m != null && !line.contains('[E]')) {
      final key = m.group(0)!;
      if (done.add(key)) stdout.writeln('  • ${m.group(1)} · ${m.group(2)} · ${m.group(3)}');
    }
    if (line.contains('✔ store_shots:')) {
      inSummary = true;
      summary = [];
    }
    if (inSummary && !line.contains('All tests passed')) summary.add(line);
    if (line.contains('[E]') || line.contains('EXCEPTION') || line.contains('Error:')) failures.add(line);
  }).asFuture<void>();
  final err = process.stderr.transform(utf8.decoder).listen(stderr.write).asFuture<void>();
  final code = await process.exitCode;
  await out;
  await err;
  if (code != 0) {
    stderr.writeln('✘ flutter test failed (exit $code). Re-run with --verbose to see the full log.');
    for (final f in failures.take(10)) {
      stderr.writeln('  $f');
    }
    exit(code);
  }
  for (final l in summary) {
    if (l.trim().isNotEmpty) stdout.writeln(l.trimRight());
  }
  final manifest = File('${cfg.output}/manifest.json');
  if (manifest.existsSync()) {
    final json = jsonDecode(manifest.readAsStringSync()) as Map<String, Object?>;
    final images = (json['images']! as List<Object?>).length;
    stdout.writeln('  $images images written · ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s including build');
  }
  if (args['open'] as bool) {
    final gallery = File('${cfg.output}/gallery.html').absolute.path;
    final opener = Platform.isMacOS ? 'open' : (Platform.isWindows ? 'start' : 'xdg-open');
    await Process.run(opener, [gallery], runInShell: Platform.isWindows);
  }
}

void _init(ArgResults args) {
  final created = <String>[];
  void create(String path, String content) {
    final f = File(path);
    if (f.existsSync()) {
      stdout.writeln('  • $path exists, kept');
      return;
    }
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
    created.add(path);
  }

  final pkg = _packageName();
  create(args['config'] as String, '''
# store_shots.yaml (everything except screens is optional)
# dart run store_shots templates | devices | frames  lists the choices.
template: aurora
devices: [iphone_6_9, android_phone]
screens:
  - id: home
    route: /
''');
  create('lib/l10n/store_en.arb', '''
{
  "app_name": "${pkg == null ? 'My App' : _title(pkg)}",
  "tagline": "Everything you need, *beautifully* simple",
  "caption_home": "Everything you need\\nin *one place*"
}
''');
  create(args['test'] as String, '''
import 'package:store_shots/store_shots.dart';
${pkg == null ? "// import 'package:your_app/main.dart';" : "import 'package:$pkg/main.dart';"}

void main() => storeShots(
  // Swap real data for fakes here (Riverpod overrides, Provider values, ...).
  overrides: (locale) => [],
  app: (overrides) => const MyApp(),
);
''');
  if (created.isNotEmpty) {
    stdout.writeln('✔ Created:\n${created.map((c) => '  • $c').join('\n')}');
  }
  stdout.writeln('\nNext: list your screens in store_shots.yaml, then run `dart run store_shots`.');
}

String? _packageName() {
  final f = File('pubspec.yaml');
  if (!f.existsSync()) return null;
  final m = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(f.readAsStringSync());
  return m?.group(1);
}

String _title(String pkg) => pkg.split('_').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join(' ');

String _n(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
