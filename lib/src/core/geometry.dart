import 'catalog.dart';

/// A plain rectangle (no Flutter dependency).
class Box {
  /// Creates a box.
  const Box(this.left, this.top, this.width, this.height);

  /// Left edge.
  final double left;

  /// Top edge.
  final double top;

  /// Width.
  final double width;

  /// Height.
  final double height;

  /// Right edge.
  double get right => left + width;

  /// Bottom edge.
  double get bottom => top + height;

  @override
  String toString() => 'Box($left, $top, $width × $height)';
}

/// Frame measurements in screen-logical units.
class FrameGeometry {
  /// Creates frame geometry.
  const FrameGeometry({
    required this.outerWidth,
    required this.outerHeight,
    required this.bezel,
    required this.rail,
    required this.outerRadius,
    required this.screen,
    required this.screenRadius,
  });

  /// Total frame width.
  final double outerWidth;

  /// Total frame height.
  final double outerHeight;

  /// Black bezel thickness (between rail and screen).
  final double bezel;

  /// Metal rail thickness (outer colored band).
  final double rail;

  /// Outer corner radius.
  final double outerRadius;

  /// Screen rectangle inside the frame.
  final Box screen;

  /// Screen corner radius.
  final double screenRadius;

  /// Aspect ratio of the whole frame.
  double get aspectRatio => outerWidth / outerHeight;
}

/// Computes the frame around a [screenWidth]×[screenHeight] screen.
FrameGeometry frameGeometry(FrameModel model, double screenWidth, double screenHeight) {
  final total = model.bezel * screenWidth;
  final rail = total * 0.5;
  final bezel = total - rail;
  final outerW = screenWidth + total * 2;
  final outerH = screenHeight + total * 2;
  final outerR = model.cornerRadius * screenWidth;
  return FrameGeometry(
    outerWidth: outerW,
    outerHeight: outerH,
    bezel: bezel,
    rail: rail,
    outerRadius: outerR,
    screen: Box(total, total, screenWidth, screenHeight),
    screenRadius: (outerR - total).clamp(0, double.infinity).toDouble(),
  );
}

/// Fits a box with [aspectRatio] (w/h) inside [maxWidth]×[maxHeight] and
/// returns its size.
({double width, double height}) fitAspect(double aspectRatio, double maxWidth, double maxHeight) {
  var w = maxWidth;
  var h = w / aspectRatio;
  if (h > maxHeight) {
    h = maxHeight;
    w = h * aspectRatio;
  }
  return (width: w, height: h);
}

/// Scale that maps a [src] size onto [dst] with "cover" semantics.
double coverScale(double srcW, double srcH, double dstW, double dstH) {
  final sx = dstW / srcW;
  final sy = dstH / srcH;
  return sx > sy ? sx : sy;
}

/// Splits a panorama of [count] panels of [panelWidth] into the left offset
/// of each panel.
List<double> panoramaOffsets(int count, double panelWidth) => [for (var i = 0; i < count; i++) i * panelWidth];
