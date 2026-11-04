import 'dart:convert';
import 'dart:io';

/// A run of caption text; [emphasis] runs are drawn in the accent color.
class CaptionSpan {
  /// Creates a span.
  const CaptionSpan(this.text, {this.emphasis = false});

  /// Text.
  final String text;

  /// Whether it was wrapped in `*stars*`.
  final bool emphasis;

  @override
  bool operator ==(Object other) => other is CaptionSpan && other.text == text && other.emphasis == emphasis;

  @override
  int get hashCode => Object.hash(text, emphasis);

  @override
  String toString() => emphasis ? '*$text*' : text;
}

/// Splits `Shop *everything*\nin one place` into spans. `*word*` marks the
/// accent part; `\n` (or a real newline) breaks the line.
List<CaptionSpan> parseCaption(String raw) {
  final text = raw.replaceAll(r'\n', '\n');
  final spans = <CaptionSpan>[];
  final re = RegExp(r'\*([^*]+)\*');
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) spans.add(CaptionSpan(text.substring(last, m.start)));
    spans.add(CaptionSpan(m.group(1)!, emphasis: true));
    last = m.end;
  }
  if (last < text.length) spans.add(CaptionSpan(text.substring(last)));
  return spans;
}

/// Plain text of a caption without markup.
String plainCaption(String raw) => parseCaption(raw).map((s) => s.text).join();

/// Captions for one locale, read from `store_<locale>.arb`.
class Captions {
  /// Creates captions from a key → text map.
  const Captions(this.locale, this.values);

  /// Loads `<dir>/store_<locale>.arb`. Falls back to `store_<language>.arb`.
  /// Missing files give empty captions (screens then show no headline).
  factory Captions.load(String dir, String locale) {
    final candidates = {locale, locale.replaceAll('-', '_'), locale.split(RegExp('[_-]')).first};
    for (final c in candidates) {
      final f = File('$dir/store_$c.arb');
      if (f.existsSync()) return Captions.parse(locale, f.readAsStringSync(), source: f.path);
    }
    return Captions(locale, const {});
  }

  /// Parses ARB JSON text. `@key` metadata entries are ignored.
  factory Captions.parse(String locale, String json, {String source = 'ARB'}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      throw FormatException('$source is not valid JSON: ${e.message}');
    }
    if (decoded is! Map) throw FormatException('$source must be a JSON object.');
    return Captions(locale, {
      for (final e in decoded.entries)
        if (!'${e.key}'.startsWith('@') && e.value is String) '${e.key}': e.value as String,
    });
  }

  /// Locale code.
  final String locale;

  /// Key → text.
  final Map<String, String> values;

  /// Text for [key], or null.
  String? operator [](String key) => values[key];
}
