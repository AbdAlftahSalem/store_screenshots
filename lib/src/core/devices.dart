/// Store devices and their official screenshot sizes.
///
/// Sources (checked November 2026):
/// * Apple: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
/// * Google Play: https://support.google.com/googleplay/android-developer/answer/9866151
library;

/// The store a device belongs to.
enum Store {
  /// Apple App Store.
  ios,

  /// Google Play.
  android,
}

/// A store screenshot target: the exact output size the store accepts and
/// the screen the app is rendered on.
class DeviceSpec {
  /// Creates a device spec.
  const DeviceSpec({
    required this.id,
    required this.label,
    required this.store,
    required this.width,
    required this.height,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
    required this.defaultFrame,
    this.playFolder = 'phoneScreenshots',
    this.statusBarHeight = 54,
    this.bottomInset = 34,
    this.tablet = false,
  });

  /// Config id, e.g. `iphone_6_9`.
  final String id;

  /// Human label, e.g. `iPhone 6.9"`.
  final String label;

  /// Which store the output is for.
  final Store store;

  /// Output width in pixels (what you upload).
  final int width;

  /// Output height in pixels (what you upload).
  final int height;

  /// Logical width of the simulated screen when drawn inside a frame.
  final double screenWidth;

  /// Logical height of the simulated screen when drawn inside a frame.
  final double screenHeight;

  /// Device pixel ratio used to render the app.
  final double pixelRatio;

  /// Frame model used when the config does not pick one.
  final String defaultFrame;

  /// fastlane supply image folder (Google Play only).
  final String playFolder;

  /// Top system inset (status bar) in logical pixels.
  final double statusBarHeight;

  /// Bottom system inset (home indicator / gesture bar) in logical pixels.
  final double bottomInset;

  /// Whether this is a tablet.
  final bool tablet;

  /// Logical screen size used to render the app.
  ///
  /// Framed shots use the real device screen. Frameless shots fill the
  /// whole store image, so the app is rendered at the output aspect ratio.
  ({double width, double height}) appSize({required bool framed}) =>
      framed ? (width: screenWidth, height: screenHeight) : (width: width / pixelRatio, height: height / pixelRatio);

  @override
  String toString() => '$label ($width×$height)';
}

/// Every device `store_shots` knows about, keyed by config id.
const Map<String, DeviceSpec> kDevices = {
  'iphone_6_9': DeviceSpec(
    id: 'iphone_6_9',
    label: 'iPhone 6.9"',
    store: Store.ios,
    width: 1320,
    height: 2868,
    screenWidth: 440,
    screenHeight: 956,
    pixelRatio: 3,
    defaultFrame: 'iphone_17_pro',
    statusBarHeight: 62,
  ),
  'iphone_6_5': DeviceSpec(
    id: 'iphone_6_5',
    label: 'iPhone 6.5"',
    store: Store.ios,
    width: 1284,
    height: 2778,
    screenWidth: 428,
    screenHeight: 926,
    pixelRatio: 3,
    defaultFrame: 'iphone_17',
    statusBarHeight: 47,
  ),
  'iphone_6_3': DeviceSpec(
    id: 'iphone_6_3',
    label: 'iPhone 6.3"',
    store: Store.ios,
    width: 1206,
    height: 2622,
    screenWidth: 402,
    screenHeight: 874,
    pixelRatio: 3,
    defaultFrame: 'iphone_17',
    statusBarHeight: 62,
  ),
  'ipad_13': DeviceSpec(
    id: 'ipad_13',
    label: 'iPad 13"',
    store: Store.ios,
    width: 2064,
    height: 2752,
    screenWidth: 1032,
    screenHeight: 1376,
    pixelRatio: 2,
    defaultFrame: 'ipad_pro',
    statusBarHeight: 32,
    bottomInset: 20,
    tablet: true,
  ),
  'android_phone': DeviceSpec(
    id: 'android_phone',
    label: 'Android phone',
    store: Store.android,
    width: 1080,
    height: 1920,
    screenWidth: 412,
    screenHeight: 892,
    pixelRatio: 2.625,
    defaultFrame: 'pixel',
    statusBarHeight: 40,
    bottomInset: 24,
  ),
  'android_tablet_7': DeviceSpec(
    id: 'android_tablet_7',
    label: 'Android 7" tablet',
    store: Store.android,
    width: 1440,
    height: 2560,
    screenWidth: 600,
    screenHeight: 960,
    pixelRatio: 2,
    defaultFrame: 'android_tablet',
    playFolder: 'sevenInchScreenshots',
    statusBarHeight: 32,
    bottomInset: 24,
    tablet: true,
  ),
  'android_tablet_10': DeviceSpec(
    id: 'android_tablet_10',
    label: 'Android 10" tablet',
    store: Store.android,
    width: 2160,
    height: 3840,
    screenWidth: 800,
    screenHeight: 1280,
    pixelRatio: 2,
    defaultFrame: 'android_tablet',
    playFolder: 'tenInchScreenshots',
    statusBarHeight: 32,
    bottomInset: 24,
    tablet: true,
  ),
};

/// Devices used when the config does not list any.
const List<String> kDefaultDevices = ['iphone_6_9', 'android_phone'];

/// Feature Graphic size required by Google Play.
const ({int width, int height}) kFeatureGraphicSize = (width: 1024, height: 500);

/// Validates a size against the Google Play rules: 320–3840 px per side and
/// the long side at most twice the short side.
bool isValidPlaySize(int width, int height) {
  final short = width < height ? width : height;
  final long = width < height ? height : width;
  return short >= 320 && long <= 3840 && long <= short * 2;
}
