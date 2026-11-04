import 'devices.dart';

const Map<String, String> _iosLocales = {
  'ar': 'ar-SA', 'ca': 'ca', 'cs': 'cs', 'da': 'da', 'de': 'de-DE', 'el': 'el', 'en': 'en-US',
  'en_AU': 'en-AU', 'en_CA': 'en-CA', 'en_GB': 'en-GB', 'es': 'es-ES', 'es_MX': 'es-MX', 'fi': 'fi',
  'fr': 'fr-FR', 'fr_CA': 'fr-CA', 'he': 'he', 'hi': 'hi', 'hr': 'hr', 'hu': 'hu', 'id': 'id', 'it': 'it',
  'ja': 'ja', 'ko': 'ko', 'ms': 'ms', 'nl': 'nl-NL', 'no': 'no', 'pl': 'pl', 'pt': 'pt-PT',
  'pt_BR': 'pt-BR', 'ro': 'ro', 'ru': 'ru', 'sk': 'sk', 'sv': 'sv', 'th': 'th', 'tr': 'tr', 'uk': 'uk',
  'vi': 'vi', 'zh': 'zh-Hans', 'zh_TW': 'zh-Hant',
};

const Map<String, String> _playLocales = {
  'ar': 'ar', 'cs': 'cs-CZ', 'da': 'da-DK', 'de': 'de-DE', 'el': 'el-GR', 'en': 'en-US', 'en_AU': 'en-AU',
  'en_CA': 'en-CA', 'en_GB': 'en-GB', 'es': 'es-ES', 'es_MX': 'es-419', 'fa': 'fa', 'fi': 'fi-FI',
  'fr': 'fr-FR', 'fr_CA': 'fr-CA', 'he': 'iw-IL', 'hi': 'hi-IN', 'hu': 'hu-HU', 'id': 'id', 'it': 'it-IT',
  'ja': 'ja-JP', 'ko': 'ko-KR', 'ms': 'ms', 'nl': 'nl-NL', 'no': 'no-NO', 'pl': 'pl-PL', 'pt': 'pt-PT',
  'pt_BR': 'pt-BR', 'ro': 'ro', 'ru': 'ru-RU', 'sv': 'sv-SE', 'th': 'th', 'tr': 'tr-TR', 'uk': 'uk',
  'ur': 'ur', 'vi': 'vi', 'zh': 'zh-CN', 'zh_TW': 'zh-TW',
};

/// Right-to-left language codes.
const Set<String> kRtlLanguages = {'ar', 'fa', 'he', 'ur', 'ps', 'ku', 'yi', 'dv', 'sd', 'ug'};

/// Whether [locale] (e.g. `ar`, `ar_EG`) is written right to left.
bool isRtl(String locale) => kRtlLanguages.contains(locale.split(RegExp('[_-]')).first);

/// Store folder name (fastlane style) for [locale].
String storeLocale(String locale, Store store, [Map<String, Map<String, String>> overrides = const {}]) {
  final o = overrides[locale]?[store.name];
  if (o != null) return o;
  final normalized = locale.replaceAll('-', '_');
  final table = store == Store.ios ? _iosLocales : _playLocales;
  return table[normalized] ?? table[normalized.split('_').first] ?? normalized.replaceAll('_', '-');
}

/// Relative path (inside the output folder) of one store screenshot.
///
/// * App Store: `ios/<locale>/<device>_<NN>_<screen>.png` (fastlane deliver).
/// * Google Play: `android/<locale>/images/<folder>/<NN>_<screen>.png`
///   (fastlane supply).
String shotPath({
  required DeviceSpec device,
  required String locale,
  required int index,
  required String screenId,
  Map<String, Map<String, String>> localeOverrides = const {},
}) {
  final n = (index + 1).toString().padLeft(2, '0');
  final loc = storeLocale(locale, device.store, localeOverrides);
  return device.store == Store.ios
      ? 'ios/$loc/${device.id}_${n}_$screenId.png'
      : 'android/$loc/images/${device.playFolder}/${n}_$screenId.png';
}

/// Relative path of the Google Play Feature Graphic for [locale].
String featureGraphicPath(String locale, [Map<String, Map<String, String>> overrides = const {}]) =>
    'android/${storeLocale(locale, Store.android, overrides)}/images/featureGraphic.png';

/// Folder prefix for a non-primary template/theme variant.
String variantPrefix(String template, String theme) => 'variants/$template-$theme/';

/// One written image, as recorded in `manifest.json`.
class ShotRecord {
  /// Creates a record.
  const ShotRecord({
    required this.path,
    required this.locale,
    required this.device,
    required this.screen,
    required this.template,
    required this.theme,
    required this.width,
    required this.height,
    this.kind = 'screenshot',
  });

  /// Reads a record from JSON.
  factory ShotRecord.fromJson(Map<String, Object?> j) => ShotRecord(
    path: j['path']! as String,
    locale: j['locale']! as String,
    device: j['device']! as String,
    screen: j['screen']! as String,
    template: j['template']! as String,
    theme: j['theme']! as String,
    width: j['width']! as int,
    height: j['height']! as int,
    kind: (j['kind'] as String?) ?? 'screenshot',
  );

  /// Path relative to the output folder.
  final String path;

  /// Locale code.
  final String locale;

  /// Device id (`feature_graphic` for the Feature Graphic).
  final String device;

  /// Screen id.
  final String screen;

  /// Template id.
  final String template;

  /// `light` or `dark`.
  final String theme;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// `screenshot` or `feature_graphic`.
  final String kind;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'path': path,
    'locale': locale,
    'device': device,
    'screen': screen,
    'template': template,
    'theme': theme,
    'width': width,
    'height': height,
    'kind': kind,
  };
}
