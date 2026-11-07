/// Names of everything a config can pick: templates, frame models and their
/// finishes. Pure data so the CLI and the config parser can validate without
/// Flutter.
library;

/// A finish (body color) of a frame model. Colors are 0xAARRGGBB.
class FrameFinish {
  /// Creates a finish.
  const FrameFinish(this.name, this.body, this.edge, this.button);

  /// Config name, e.g. `deep_blue`.
  final String name;

  /// Main body color.
  final int body;

  /// Highlight color along the edge.
  final int edge;

  /// Side button color.
  final int button;
}

/// The shape family of a frame model.
enum FrameShape {
  /// iPhone-style: Dynamic Island pill.
  island,

  /// Android-style: centered punch hole.
  punchHole,

  /// Tablet: thin even bezel, small camera dot.
  tablet,
}

/// A device frame model drawn in Dart.
class FrameModel {
  /// Creates a frame model.
  const FrameModel({
    required this.id,
    required this.label,
    required this.shape,
    required this.finishes,
    required this.bezel,
    required this.cornerRadius,
    this.flatEdges = false,
    this.cutoutScale = 1,
  });

  /// Config id, e.g. `iphone_17_pro`.
  final String id;

  /// Human label.
  final String label;

  /// Shape family.
  final FrameShape shape;

  /// Available finishes; the first is the default.
  final List<FrameFinish> finishes;

  /// Bezel thickness as a fraction of the screen width.
  final double bezel;

  /// Outer corner radius as a fraction of the screen width.
  final double cornerRadius;

  /// Flat (squared) side rails instead of rounded ones.
  final bool flatEdges;

  /// Size multiplier for the camera cutout.
  final double cutoutScale;

  /// Finds a finish by name or returns `null`.
  FrameFinish? finish(String name) {
    for (final f in finishes) {
      if (f.name == name) return f;
    }
    return null;
  }
}

/// Frame models: three iPhone-inspired, three Android-inspired and two
/// tablets. Shapes are generic ("inspired by"); no brand artwork or logos.
const Map<String, FrameModel> kFrameModels = {
  'iphone_17': FrameModel(
    id: 'iphone_17',
    label: 'iPhone 17 style',
    shape: FrameShape.island,
    bezel: 0.042,
    cornerRadius: 0.155,
    finishes: [
      FrameFinish('black', 0xFF1F2023, 0xFF4A4B50, 0xFF2A2B2F),
      FrameFinish('white', 0xFFE9E7E4, 0xFFFFFFFF, 0xFFD6D3CF),
      FrameFinish('lavender', 0xFFC9B9DE, 0xFFE6DCF2, 0xFFB7A5CF),
      FrameFinish('sage', 0xFFB4C2A4, 0xFFD5DFC9, 0xFFA1B091),
      FrameFinish('mist_blue', 0xFFA9BED3, 0xFFD3E0EC, 0xFF97AEC5),
    ],
  ),
  'iphone_17_pro': FrameModel(
    id: 'iphone_17_pro',
    label: 'iPhone 17 Pro style',
    shape: FrameShape.island,
    bezel: 0.040,
    cornerRadius: 0.16,
    flatEdges: true,
    finishes: [
      FrameFinish('cosmic_orange', 0xFFD9692E, 0xFFF59A5F, 0xFFC25A23),
      FrameFinish('deep_blue', 0xFF2B3A55, 0xFF5A6E92, 0xFF223047),
      FrameFinish('silver', 0xFFD7D8DA, 0xFFF5F6F7, 0xFFC4C5C8),
      FrameFinish('desert_titanium', 0xFFB9A48B, 0xFFDCCBB5, 0xFFA8937A),
    ],
  ),
  'iphone_air': FrameModel(
    id: 'iphone_air',
    label: 'iPhone Air style',
    shape: FrameShape.island,
    bezel: 0.034,
    cornerRadius: 0.15,
    finishes: [
      FrameFinish('space_black', 0xFF151517, 0xFF3C3C40, 0xFF222225),
      FrameFinish('cloud_white', 0xFFF1F0EC, 0xFFFFFFFF, 0xFFDEDCD6),
      FrameFinish('light_gold', 0xFFE8D9BC, 0xFFF7EEDC, 0xFFD6C4A2),
      FrameFinish('sky_blue', 0xFFBFD6EA, 0xFFE2EEF8, 0xFFA9C4DC),
    ],
  ),
  'pixel': FrameModel(
    id: 'pixel',
    label: 'Pixel style',
    shape: FrameShape.punchHole,
    bezel: 0.045,
    cornerRadius: 0.13,
    finishes: [
      FrameFinish('obsidian', 0xFF202124, 0xFF4B4D52, 0xFF2B2C30),
      FrameFinish('porcelain', 0xFFEDE7DF, 0xFFFFFFFF, 0xFFD9D2C8),
      FrameFinish('moonstone', 0xFF8B97A6, 0xFFB7C1CD, 0xFF778493),
      FrameFinish('peony', 0xFFF2B8C6, 0xFFFAD9E1, 0xFFE3A1B1),
    ],
  ),
  'galaxy': FrameModel(
    id: 'galaxy',
    label: 'Galaxy style',
    shape: FrameShape.punchHole,
    bezel: 0.032,
    cornerRadius: 0.085,
    flatEdges: true,
    cutoutScale: 0.85,
    finishes: [
      FrameFinish('titanium_black', 0xFF26272A, 0xFF55575C, 0xFF303135),
      FrameFinish('titanium_gray', 0xFF8E8F91, 0xFFC1C2C4, 0xFF7C7D80),
      FrameFinish('titanium_silverblue', 0xFF9FB1C4, 0xFFCAD6E2, 0xFF8A9DB2),
      FrameFinish('icy_blue', 0xFFB9D3E8, 0xFFE0EDF7, 0xFFA3C1DB),
    ],
  ),
  'android_classic': FrameModel(
    id: 'android_classic',
    label: 'Classic Android',
    shape: FrameShape.punchHole,
    bezel: 0.055,
    cornerRadius: 0.14,
    cutoutScale: 1.1,
    finishes: [
      FrameFinish('black', 0xFF18191B, 0xFF3F4045, 0xFF242528),
      FrameFinish('white', 0xFFF2F2F0, 0xFFFFFFFF, 0xFFDCDCD9),
      FrameFinish('mint', 0xFFA9DCC8, 0xFFD4F0E5, 0xFF92CBB4),
    ],
  ),
  'ipad_pro': FrameModel(
    id: 'ipad_pro',
    label: 'iPad Pro style',
    shape: FrameShape.tablet,
    bezel: 0.035,
    cornerRadius: 0.06,
    flatEdges: true,
    finishes: [
      FrameFinish('space_black', 0xFF1C1C1E, 0xFF45454A, 0xFF28282B),
      FrameFinish('silver', 0xFFDADBDD, 0xFFF6F7F8, 0xFFC6C7CA),
    ],
  ),
  'android_tablet': FrameModel(
    id: 'android_tablet',
    label: 'Android tablet',
    shape: FrameShape.tablet,
    bezel: 0.04,
    cornerRadius: 0.055,
    finishes: [
      FrameFinish('graphite', 0xFF2A2B2E, 0xFF55575B, 0xFF333438),
      FrameFinish('silver', 0xFFD9DADC, 0xFFF4F5F6, 0xFFC5C6C9),
    ],
  ),
};

/// Template ids, in gallery order. See the README for what each looks like.
const List<String> kTemplates = [
  'aurora',
  'clean',
  'midnight',
  'tilted',
  'duo',
  'panorama',
  'bold',
  'glass',
  'spotlight',
  'pastel',
];

/// Default template.
const String kDefaultTemplate = 'aurora';

/// One-line descriptions shown by `dart run store_screenshots templates`.
const Map<String, String> kTemplateDescriptions = {
  'aurora': 'Deep indigo with glowing aurora blobs, white headline',
  'clean': 'Soft light gray, dark headline, Apple-keynote calm',
  'midnight': 'Near-black with a neon glow behind the device',
  'tilted': '3D-tilted device on a vivid gradient',
  'duo': 'Two devices: the next screen peeks from behind',
  'panorama': 'One continuous scene sliced across all screenshots',
  'bold': 'Huge headline, solid color, device bleeding off the edge',
  'glass': 'Mesh gradient with a frosted-glass headline card',
  'spotlight': 'Dark stage that zooms into your highlighted widget',
  'pastel': 'Playful pastel shapes and a slightly rotated device',
};
