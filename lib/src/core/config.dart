import 'dart:io';

import 'package:yaml/yaml.dart';

import 'catalog.dart';
import 'devices.dart';

/// Thrown when `store_shots.yaml` has a problem. The message says what is
/// wrong and how to fix it.
class ConfigException implements Exception {
  /// Creates a config error.
  ConfigException(this.message);

  /// Human readable explanation.
  final String message;

  @override
  String toString() => 'store_shots.yaml: $message';
}

/// How highlights are drawn.
enum HighlightStyle {
  /// A glowing ring around the widget.
  ring,

  /// A curved arrow pointing at the widget.
  arrow,

  /// Dims everything except the widget.
  spotlight,
}

/// Highlight a widget found by its `Key`.
class HighlightConfig {
  /// Creates a highlight.
  const HighlightConfig({required this.key, this.style = HighlightStyle.ring, this.label});

  /// The `ValueKey<String>` value of the widget to highlight.
  final String key;

  /// How to draw it.
  final HighlightStyle style;

  /// Optional ARB key of a short label shown next to the highlight.
  final String? label;
}

/// One screen to capture.
class ScreenConfig {
  /// Creates a screen.
  const ScreenConfig({
    required this.id,
    required this.route,
    required this.caption,
    this.subtitle,
    this.highlight,
    this.template,
  });

  /// Short id used in file names, e.g. `home`.
  final String id;

  /// Route the app starts on, e.g. `/product/1`.
  final String route;

  /// ARB key of the headline.
  final String caption;

  /// ARB key of the optional smaller line under the headline.
  final String? subtitle;

  /// Optional highlight.
  final HighlightConfig? highlight;

  /// Per-screen template override.
  final String? template;
}

/// A frame model + finish.
class FrameChoice {
  /// Creates a frame choice.
  const FrameChoice(this.model, this.finish);

  /// Frame model.
  final FrameModel model;

  /// Finish (color).
  final FrameFinish finish;

  @override
  String toString() => '${model.id}/${finish.name}';
}

/// Background override: a solid color or a gradient (0xAARRGGBB ints).
class BackgroundConfig {
  /// Creates a background.
  const BackgroundConfig(this.colors);

  /// One color = solid, two or more = gradient.
  final List<int> colors;
}

/// Status bar mock settings.
class StatusBarConfig {
  /// Creates status bar settings.
  const StatusBarConfig({this.enabled = true, this.time = '9:41', this.battery = 100});

  /// Draw the status bar at all.
  final bool enabled;

  /// Clock text.
  final String time;

  /// Battery percent 0–100.
  final int battery;
}

/// The parsed `store_shots.yaml`.
class StoreShotsConfig {
  /// Creates a config. Prefer [StoreShotsConfig.parse] / [StoreShotsConfig.load].
  StoreShotsConfig({
    required this.appName,
    required this.output,
    required this.locales,
    required this.devices,
    required this.templates,
    required this.themes,
    required this.frame,
    required this.frames,
    required this.statusBar,
    required this.screens,
    required this.captionsDir,
    this.background,
    this.accent,
    this.captionColor,
    this.featureGraphic = true,
    this.tagline = 'tagline',
    this.platform = 'auto',
    this.storeLocales = const {},
    this.waitMs = 400,
  });

  /// App name (Feature Graphic, gallery title).
  final String appName;

  /// Output folder.
  final String output;

  /// Locales to render, e.g. `[en, ar]`.
  final List<String> locales;

  /// Devices to render.
  final List<DeviceSpec> devices;

  /// Templates to render. The first one is the store set; others go to
  /// `variants/`.
  final List<String> templates;

  /// `light`, `dark` or both.
  final List<String> themes;

  /// Draw a device frame.
  final bool frame;

  /// Frame per store.
  final Map<Store, FrameChoice> frames;

  /// Status bar mock.
  final StatusBarConfig statusBar;

  /// Screens in store order.
  final List<ScreenConfig> screens;

  /// Folder with `store_<locale>.arb` caption files.
  final String captionsDir;

  /// Background override (else the template's).
  final BackgroundConfig? background;

  /// Accent color override.
  final int? accent;

  /// Headline color override.
  final int? captionColor;

  /// Generate the Google Play Feature Graphic.
  final bool featureGraphic;

  /// ARB key used as the Feature Graphic tagline.
  final String tagline;

  /// `auto` (iOS look for App Store devices), `android`, `ios` or `none`.
  final String platform;

  /// Overrides for store locale folder names: `{ar: {ios: ar-SA, android: ar}}`.
  final Map<String, Map<String, String>> storeLocales;

  /// Extra settle time per screen in milliseconds.
  final int waitMs;

  /// Primary template (the one written to the store folders).
  String get template => templates.first;

  /// Number of store screenshots one run makes for the primary template.
  int get shotCount => screens.length * locales.length * devices.length;

  /// Loads and parses a config file.
  static StoreShotsConfig load(String path, {String? projectDir}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigException('file not found at "$path". Run `dart run store_shots init` to create one.');
    }
    return parse(file.readAsStringSync(), projectDir: projectDir ?? file.parent.path);
  }

  /// Parses YAML text.
  static StoreShotsConfig parse(String yamlText, {String projectDir = '.'}) {
    final Object? doc;
    try {
      doc = loadYaml(yamlText);
    } on YamlException catch (e) {
      throw ConfigException('invalid YAML: ${e.message}');
    }
    final map = doc == null ? <String, Object?>{} : _asMap(doc, 'top level');
    _checkKeys(map, const {
      'app_name', 'output', 'locales', 'devices', 'template', 'templates', 'theme', 'frame', 'frames',
      'status_bar', 'background', 'accent', 'caption_color', 'screens', 'captions', 'feature_graphic',
      'tagline', 'platform', 'store_locales', 'wait_ms',
    }, 'top level');

    final captionsDir = _string(map['captions'], 'captions') ?? _findCaptionsDir(projectDir);

    // Locales: explicit, else every store_<locale>.arb we can find, else en.
    var locales = _stringList(map['locales'], 'locales');
    if (locales == null || locales.isEmpty) {
      locales = _localesFromArb(projectDir, captionsDir);
      if (locales.isEmpty) locales = ['en'];
    }
    for (final l in locales) {
      if (!RegExp(r'^[a-z]{2,3}([_-][A-Za-z0-9]{2,4})?$').hasMatch(l)) {
        throw ConfigException('locale "$l" is not a locale code (use e.g. en, ar, pt_BR).');
      }
    }

    final deviceIds = _stringList(map['devices'], 'devices') ?? kDefaultDevices;
    if (deviceIds.isEmpty) throw ConfigException('devices: list at least one device.');
    final devices = [
      for (final id in deviceIds)
        kDevices[id] ?? (throw ConfigException('unknown device "$id".${_suggest(id, kDevices.keys)} '
            'Known: ${kDevices.keys.join(', ')}.')),
    ];

    final templates = <String>[];
    final t = map['templates'] ?? map['template'];
    if (t == 'all') {
      templates.addAll(kTemplates);
    } else {
      templates.addAll(_stringList(t, 'template') ?? const [kDefaultTemplate]);
    }
    for (final id in templates) {
      if (!kTemplates.contains(id) && id != 'none') {
        throw ConfigException('unknown template "$id".${_suggest(id, kTemplates)} Known: ${kTemplates.join(', ')}.');
      }
    }
    if (templates.isEmpty) templates.add(kDefaultTemplate);

    final themes = _stringList(map['theme'], 'theme') ?? const ['light'];
    for (final th in themes) {
      if (th != 'light' && th != 'dark') throw ConfigException('theme must be light, dark or [light, dark], got "$th".');
    }

    var frame = true;
    final frames = <Store, FrameChoice>{};
    final f = map['frame'];
    if (f is bool) {
      frame = f;
    } else if (f is String) {
      final c = parseFrameChoice(f, 'frame');
      frames[c.model.shape == FrameShape.island || c.model.id == 'ipad_pro' ? Store.ios : Store.android] = c;
    } else if (f != null) {
      throw ConfigException('frame must be true, false or a model like "iphone_17_pro/deep_blue".');
    }
    final fm = map['frames'];
    if (fm != null) {
      final m = _asMap(fm, 'frames');
      _checkKeys(m, const {'ios', 'android'}, 'frames');
      if (m['ios'] != null) frames[Store.ios] = parseFrameChoice(_frameString(m['ios'], 'frames.ios'), 'frames.ios');
      if (m['android'] != null) {
        frames[Store.android] = parseFrameChoice(_frameString(m['android'], 'frames.android'), 'frames.android');
      }
    }

    var statusBar = const StatusBarConfig();
    final sb = map['status_bar'];
    if (sb is bool) {
      statusBar = StatusBarConfig(enabled: sb);
    } else if (sb != null) {
      final m = _asMap(sb, 'status_bar');
      _checkKeys(m, const {'time', 'battery', 'enabled'}, 'status_bar');
      final battery = m['battery'] ?? 100;
      if (battery is! int || battery < 0 || battery > 100) {
        throw ConfigException('status_bar.battery must be a number from 0 to 100.');
      }
      statusBar = StatusBarConfig(
        enabled: m['enabled'] != false,
        time: '${m['time'] ?? '9:41'}',
        battery: battery,
      );
    }

    BackgroundConfig? background;
    final bg = map['background'];
    if (bg is String) {
      background = BackgroundConfig([parseColor(bg, 'background')]);
    } else if (bg != null) {
      final m = _asMap(bg, 'background');
      _checkKeys(m, const {'color', 'gradient'}, 'background');
      if (m['gradient'] != null) {
        final colors = _stringList(m['gradient'], 'background.gradient')!;
        if (colors.length < 2) throw ConfigException('background.gradient needs at least two colors.');
        background = BackgroundConfig([for (final c in colors) parseColor(c, 'background.gradient')]);
      } else if (m['color'] != null) {
        background = BackgroundConfig([parseColor('${m['color']}', 'background.color')]);
      }
    }

    final screensRaw = map['screens'];
    final screens = <ScreenConfig>[];
    if (screensRaw == null) {
      screens.add(const ScreenConfig(id: 'home', route: '/', caption: 'caption_home'));
    } else if (screensRaw is! YamlList) {
      throw ConfigException('screens must be a list, e.g.\n  screens:\n    - id: home\n      route: /');
    } else {
      for (var i = 0; i < screensRaw.length; i++) {
        screens.add(_parseScreen(screensRaw[i], i));
      }
    }
    final ids = <String>{};
    for (final s in screens) {
      if (!ids.add(s.id)) throw ConfigException('screen id "${s.id}" is used twice.');
    }
    if (screens.length > 8 && devices.any((d) => d.store == Store.android)) {
      throw ConfigException('Google Play allows at most 8 screenshots per device type; you listed ${screens.length} screens.');
    }
    if (screens.length > 10) {
      throw ConfigException('the App Store allows at most 10 screenshots per device size; you listed ${screens.length}.');
    }

    final platform = _string(map['platform'], 'platform') ?? 'auto';
    if (!const {'auto', 'ios', 'android', 'none'}.contains(platform)) {
      throw ConfigException('platform must be auto, ios, android or none.');
    }

    final storeLocales = <String, Map<String, String>>{};
    final sl = map['store_locales'];
    if (sl != null) {
      _asMap(sl, 'store_locales').forEach((k, v) {
        final m = _asMap(v, 'store_locales.$k');
        storeLocales[k] = {for (final e in m.entries) e.key: '${e.value}'};
      });
    }

    final fg = map['feature_graphic'];
    final waitMs = map['wait_ms'] ?? 400;
    if (waitMs is! int || waitMs < 0) throw ConfigException('wait_ms must be a positive number.');

    return StoreShotsConfig(
      appName: _string(map['app_name'], 'app_name') ?? _pubspecName(projectDir) ?? 'My App',
      output: _string(map['output'], 'output') ?? 'build/store_shots',
      locales: locales,
      devices: devices,
      templates: templates,
      themes: themes,
      frame: frame,
      frames: frames,
      statusBar: statusBar,
      screens: screens,
      captionsDir: captionsDir,
      background: background,
      accent: map['accent'] == null ? null : parseColor('${map['accent']}', 'accent'),
      captionColor: map['caption_color'] == null ? null : parseColor('${map['caption_color']}', 'caption_color'),
      featureGraphic: fg != false,
      tagline: _string(map['tagline'], 'tagline') ?? 'tagline',
      platform: platform,
      storeLocales: storeLocales,
      waitMs: waitMs,
    );
  }

  /// The frame to draw for [device]. Without a choice in the config, the
  /// device's default model is used with a finish that suits the template
  /// ([lightFinish] for light backgrounds).
  FrameChoice frameFor(DeviceSpec device, {bool lightFinish = false}) {
    final chosen = frames[device.store];
    if (chosen != null && (chosen.model.shape == FrameShape.tablet) == device.tablet) return chosen;
    final model = kFrameModels[device.defaultFrame]!;
    final sorted = [...model.finishes]..sort((a, b) => _luma(a.body).compareTo(_luma(b.body)));
    return FrameChoice(model, lightFinish ? sorted.last : sorted.first);
  }

  static double _luma(int c) => 0.2126 * ((c >> 16) & 0xFF) + 0.7152 * ((c >> 8) & 0xFF) + 0.0722 * (c & 0xFF);
}

/// Parses `model` or `model/finish` (also `model:finish`).
FrameChoice parseFrameChoice(String value, String where) {
  final parts = value.split(RegExp(r'[/:]'));
  final model = kFrameModels[parts.first.trim()];
  if (model == null) {
    throw ConfigException('$where: unknown frame "${parts.first}".${_suggest(parts.first, kFrameModels.keys)} '
        'Known: ${kFrameModels.keys.join(', ')}.');
  }
  if (parts.length < 2) return FrameChoice(model, model.finishes.first);
  final finish = model.finish(parts[1].trim());
  if (finish == null) {
    throw ConfigException('$where: ${model.id} has no color "${parts[1]}". '
        'Colors: ${model.finishes.map((f) => f.name).join(', ')}.');
  }
  return FrameChoice(model, finish);
}

/// Parses `#RGB`, `#RRGGBB`, `#AARRGGBB` or `0xAARRGGBB` into an ARGB int.
int parseColor(String value, String where) {
  var v = value.trim();
  if (v.startsWith('#')) {
    v = v.substring(1);
  } else if (v.startsWith('0x') || v.startsWith('0X')) {
    v = v.substring(2);
  }
  if (v.length == 3) v = v.split('').map((c) => '$c$c').join();
  if (v.length == 6) v = 'FF$v';
  final parsed = v.length == 8 ? int.tryParse(v, radix: 16) : null;
  if (parsed == null) throw ConfigException('$where: "$value" is not a color (use "#4F46E5").');
  return parsed;
}

ScreenConfig _parseScreen(Object? raw, int index) {
  if (raw is String) {
    return ScreenConfig(id: raw, route: raw == 'home' ? '/' : '/$raw', caption: 'caption_$raw');
  }
  final m = _asMap(raw, 'screens[$index]');
  _checkKeys(m, const {'id', 'route', 'caption', 'subtitle', 'highlight', 'template'}, 'screens[$index]');
  final id = _string(m['id'], 'screens[$index].id');
  if (id == null || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
    throw ConfigException('screens[$index] needs an id made of letters, digits, _ or - (e.g. id: home).');
  }
  final route = _string(m['route'], 'screens[$index].route') ?? (id == 'home' ? '/' : '/$id');
  if (!route.startsWith('/')) throw ConfigException('screens[$index].route must start with "/", got "$route".');
  HighlightConfig? highlight;
  final h = m['highlight'];
  if (h is String) {
    highlight = HighlightConfig(key: h);
  } else if (h != null) {
    final hm = _asMap(h, 'screens[$index].highlight');
    _checkKeys(hm, const {'key', 'style', 'label'}, 'screens[$index].highlight');
    final key = _string(hm['key'], 'screens[$index].highlight.key');
    if (key == null) throw ConfigException('screens[$index].highlight needs a key (the ValueKey of the widget).');
    final style = _string(hm['style'], 'screens[$index].highlight.style') ?? 'ring';
    final parsed = HighlightStyle.values.where((s) => s.name == style);
    if (parsed.isEmpty) throw ConfigException('highlight.style must be ring, arrow or spotlight.');
    highlight = HighlightConfig(key: key, style: parsed.first, label: _string(hm['label'], 'highlight.label'));
  }
  final template = _string(m['template'], 'screens[$index].template');
  if (template != null && !kTemplates.contains(template)) {
    throw ConfigException('screens[$index]: unknown template "$template".${_suggest(template, kTemplates)}');
  }
  return ScreenConfig(
    id: id,
    route: route,
    caption: _string(m['caption'], 'screens[$index].caption') ?? 'caption_$id',
    subtitle: _string(m['subtitle'], 'screens[$index].subtitle'),
    highlight: highlight,
    template: template,
  );
}

Map<String, Object?> _asMap(Object? v, String where) {
  if (v is Map) return {for (final e in v.entries) '${e.key}': e.value};
  throw ConfigException('$where must be a map (key: value).');
}

void _checkKeys(Map<String, Object?> m, Set<String> known, String where) {
  for (final k in m.keys) {
    if (!known.contains(k)) {
      throw ConfigException('unknown option "$k" in $where.${_suggest(k, known)}');
    }
  }
}

String? _string(Object? v, String where) {
  if (v == null) return null;
  if (v is String || v is num || v is bool) return '$v';
  throw ConfigException('$where must be text.');
}

String _frameString(Object? v, String where) {
  if (v is String) return v;
  final m = _asMap(v, where);
  final model = m['model'];
  if (model == null) throw ConfigException('$where needs a model, e.g. {model: pixel, color: obsidian}.');
  return m['color'] == null ? '$model' : '$model/${m['color']}';
}

List<String>? _stringList(Object? v, String where) {
  if (v == null) return null;
  if (v is String) return [v];
  if (v is List) return [for (final e in v) '$e'];
  throw ConfigException('$where must be a list like [a, b].');
}

String _findCaptionsDir(String projectDir) {
  for (final c in const ['lib/l10n', 'l10n', 'store_shots', 'assets/l10n']) {
    final d = Directory('$projectDir/$c');
    if (d.existsSync() && d.listSync().any((e) => _arbLocale(e.path) != null)) return c;
  }
  return 'lib/l10n';
}

List<String> _localesFromArb(String projectDir, String captionsDir) {
  final d = Directory('$projectDir/$captionsDir');
  if (!d.existsSync()) return [];
  final found = <String>[
    for (final e in d.listSync()) ?_arbLocale(e.path),
  ]..sort();
  // English first: it is usually the primary store listing.
  if (found.remove('en')) found.insert(0, 'en');
  return found;
}

String? _arbLocale(String path) {
  final m = RegExp(r'store_([A-Za-z_]+)\.arb$').firstMatch(path.replaceAll('\\', '/'));
  return m?.group(1);
}

String? _pubspecName(String projectDir) {
  final f = File('$projectDir/pubspec.yaml');
  if (!f.existsSync()) return null;
  try {
    final y = loadYaml(f.readAsStringSync());
    final name = y is Map ? y['name'] : null;
    if (name is! String) return null;
    return name.split('_').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join(' ');
  } on Object {
    return null;
  }
}

String _suggest(String input, Iterable<String> options) {
  String? best;
  var bestScore = 1 << 30;
  for (final o in options) {
    final d = levenshtein(input, o);
    if (d < bestScore) {
      bestScore = d;
      best = o;
    }
  }
  return best != null && bestScore <= (input.length / 2).ceil() ? ' Did you mean "$best"?' : '';
}

/// Edit distance, used for "did you mean" hints.
int levenshtein(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}
