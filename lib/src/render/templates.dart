import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/captions.dart';
import '../core/config.dart';
import '../core/devices.dart';
import '../core/geometry.dart';
import 'backdrops.dart';
import 'device_frame.dart';

/// How a template arranges headline and device(s).
enum TemplateLayout {
  /// Headline on top, device below.
  classic,

  /// Headline top-start, device tilted in 3D.
  tilted,

  /// Two devices.
  duo,

  /// Continuous scene across screenshots.
  panorama,

  /// Huge headline, device bleeding off the bottom.
  bold,

  /// Headline in a frosted glass card.
  glass,

  /// Device plus a zoomed callout of the highlighted widget.
  spotlight,

  /// Slightly rotated device, playful.
  playful,
}

/// The look of one template.
class TemplateStyle {
  /// Creates a template style.
  const TemplateStyle({
    required this.id,
    required this.layout,
    required this.backdrop,
    required this.colors,
    required this.caption,
    required this.emphasis,
    required this.accent,
    this.align = TextAlign.center,
    this.weight = FontWeight.w700,
    this.sizeFactor = 1,
    this.subtitleOpacity = 0.72,
    this.lightFrame = false,
  });

  /// Prefer a light frame finish when the config does not pick one.
  final bool lightFrame;

  /// Template id.
  final String id;

  /// Layout.
  final TemplateLayout layout;

  /// Background kind.
  final BackdropKind backdrop;

  /// Background colors.
  final List<Color> colors;

  /// Headline color.
  final Color caption;

  /// Color of `*emphasis*` words.
  final Color emphasis;

  /// Accent (highlights, glows).
  final Color accent;

  /// Headline alignment (start/center).
  final TextAlign align;

  /// Headline weight.
  final FontWeight weight;

  /// Headline size multiplier.
  final double sizeFactor;

  /// Subtitle opacity.
  final double subtitleOpacity;

  /// Applies config overrides.
  TemplateStyle withOverrides({List<Color>? colors, Color? accent, Color? caption}) => TemplateStyle(
    id: id,
    layout: layout,
    backdrop: backdrop,
    colors: colors ?? this.colors,
    caption: caption ?? this.caption,
    emphasis: accent ?? emphasis,
    accent: accent ?? this.accent,
    align: align,
    weight: weight,
    sizeFactor: sizeFactor,
    subtitleOpacity: subtitleOpacity,
    lightFrame: lightFrame,
  );
}

/// The ten built-in templates.
const Map<String, TemplateStyle> kTemplateStyles = {
  'aurora': TemplateStyle(
    id: 'aurora',
    layout: TemplateLayout.classic,
    backdrop: BackdropKind.aurora,
    colors: [Color(0xFF0B1026), Color(0xFF1E1450), Color(0xFF0B1026)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFF67E8F9),
    accent: Color(0xFF8B5CF6),
  ),
  'clean': TemplateStyle(
    id: 'clean',
    layout: TemplateLayout.classic,
    backdrop: BackdropKind.clean,
    colors: [Color(0xFFF7F7FA), Color(0xFFE6E8EF)],
    caption: Color(0xFF0B0B12),
    emphasis: Color(0xFF4F46E5),
    accent: Color(0xFF4F46E5),
    weight: FontWeight.w600,
    subtitleOpacity: 0.6,
    lightFrame: true,
  ),
  'midnight': TemplateStyle(
    id: 'midnight',
    layout: TemplateLayout.classic,
    backdrop: BackdropKind.midnight,
    colors: [Color(0xFF050507), Color(0xFF0D0B14)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFFC4B5FD),
    accent: Color(0xFF7C3AED),
  ),
  'tilted': TemplateStyle(
    id: 'tilted',
    layout: TemplateLayout.tilted,
    backdrop: BackdropKind.gradient,
    colors: [Color(0xFFFF6A3D), Color(0xFFE8336D), Color(0xFF7B2FF7)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFFFFE066),
    accent: Color(0xFFFFE066),
    align: TextAlign.start,
    weight: FontWeight.w800,
  ),
  'duo': TemplateStyle(
    id: 'duo',
    layout: TemplateLayout.duo,
    backdrop: BackdropKind.gradient,
    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB), Color(0xFF1E1B4B)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFFA5F3FC),
    accent: Color(0xFF22D3EE),
  ),
  'panorama': TemplateStyle(
    id: 'panorama',
    layout: TemplateLayout.panorama,
    backdrop: BackdropKind.gradient,
    colors: [Color(0xFF00C9A7), Color(0xFF0081CF), Color(0xFF4B3FD8), Color(0xFF9B2FD3)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFFFFF3B0),
    accent: Color(0xFFFFD166),
  ),
  'bold': TemplateStyle(
    id: 'bold',
    layout: TemplateLayout.bold,
    backdrop: BackdropKind.solid,
    colors: [Color(0xFFFF5A1F)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFF1A1A1A),
    accent: Color(0xFF1A1A1A),
    align: TextAlign.start,
    weight: FontWeight.w800,
    sizeFactor: 1.32,
  ),
  'glass': TemplateStyle(
    id: 'glass',
    layout: TemplateLayout.glass,
    backdrop: BackdropKind.mesh,
    colors: [Color(0xFFFFB199), Color(0xFFFF0844), Color(0xFF7F7FD5), Color(0xFF86A8E7)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFFFFF1A8),
    accent: Color(0xFFFF2E63),
    weight: FontWeight.w700,
    lightFrame: true,
  ),
  'spotlight': TemplateStyle(
    id: 'spotlight',
    layout: TemplateLayout.spotlight,
    backdrop: BackdropKind.stage,
    colors: [Color(0xFF070B18), Color(0xFF101A33)],
    caption: Color(0xFFFFFFFF),
    emphasis: Color(0xFFFFC23D),
    accent: Color(0xFFFFC23D),
  ),
  'pastel': TemplateStyle(
    id: 'pastel',
    layout: TemplateLayout.playful,
    backdrop: BackdropKind.pastel,
    colors: [Color(0xFFFFF6EE)],
    caption: Color(0xFF1F1B2E),
    emphasis: Color(0xFFE85D75),
    accent: Color(0xFF7B61FF),
    weight: FontWeight.w800,
    lightFrame: true,
  ),
};

/// Everything a template needs to draw one store image.
class ShotScene {
  /// Creates a scene.
  const ShotScene({
    required this.style,
    required this.device,
    required this.frame,
    required this.config,
    required this.shots,
    required this.index,
    required this.headline,
    required this.subtitle,
    required this.rtl,
  });

  /// Template style (with overrides applied).
  final TemplateStyle style;

  /// Store device.
  final DeviceSpec device;

  /// Frame choice.
  final FrameChoice frame;

  /// Run config.
  final StoreShotsConfig config;

  /// All captured screens for this locale/device, in order.
  final List<ScreenShot> shots;

  /// Index of the screen this image is for.
  final int index;

  /// Raw headline (may contain `*emphasis*`).
  final String headline;

  /// Raw subtitle or empty.
  final String subtitle;

  /// Right-to-left locale.
  final bool rtl;

  /// The current screen.
  ScreenShot get shot => shots[index];

  /// Text direction.
  TextDirection get direction => rtl ? TextDirection.rtl : TextDirection.ltr;
}

/// Headline + subtitle typography helpers.
class CaptionLayout {
  CaptionLayout._(this.painter, this.subPainter, this.fontSize, this.gap);

  /// Headline painter.
  final TextPainter painter;

  /// Subtitle painter (may be null).
  final TextPainter? subPainter;

  /// Chosen font size.
  final double fontSize;

  /// Gap between headline and subtitle.
  final double gap;

  /// Total height.
  double get height => painter.height + (subPainter == null ? 0 : gap + subPainter!.height);

  /// Lays out a caption, shrinking the font until it fits [maxLines].
  static CaptionLayout measure({
    required String headline,
    required String subtitle,
    required TemplateStyle style,
    required double maxWidth,
    required double baseSize,
    required bool rtl,
    int maxLines = 3,
    TextAlign? align,
    double? maxHeight,
  }) {
    var size = baseSize * style.sizeFactor;
    late TextPainter tp;
    for (var i = 0; i < 24; i++) {
      tp = TextPainter(
        text: captionSpan(headline, style, size, rtl),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        textAlign: align ?? style.align,
        maxLines: maxLines + 1,
      )..layout(maxWidth: maxWidth);
      final lines = tp.computeLineMetrics().length;
      final tooTall = maxHeight != null && tp.height > maxHeight;
      if (lines <= maxLines && !tooTall && !_breaksWords(headline, tp, maxWidth, size, style, rtl)) break;
      size *= 0.93;
    }
    TextPainter? sub;
    if (subtitle.trim().isNotEmpty) {
      sub = TextPainter(
        text: TextSpan(
          text: plainCaption(subtitle),
          style: _font(rtl).copyWith(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w500,
            height: rtl ? 1.5 : 1.35,
            color: style.caption.withValues(alpha: style.subtitleOpacity),
          ),
        ),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        textAlign: align ?? style.align,
        maxLines: 3,
      )..layout(maxWidth: maxWidth);
    }
    return CaptionLayout._(tp, sub, size, size * 0.38);
  }

  // A single long word wider than the box would be split mid-word; shrink instead.
  static bool _breaksWords(String headline, TextPainter tp, double maxWidth, double size, TemplateStyle style, bool rtl) {
    for (final word in plainCaption(headline).split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final w = TextPainter(
        text: TextSpan(text: word, style: _font(rtl).copyWith(fontSize: size, fontWeight: style.weight)),
        textDirection: TextDirection.ltr,
      )..layout();
      if (w.width > maxWidth) return true;
    }
    return false;
  }

  /// Paints the caption with its top-left at [offset] inside a box of [width].
  void paint(Canvas canvas, Offset offset, double width, TextAlign align, bool rtl) {
    double dx(TextPainter p) {
      final a = align == TextAlign.start ? (rtl ? TextAlign.right : TextAlign.left) : align;
      return switch (a) {
        TextAlign.center => (width - p.width) / 2,
        TextAlign.right || TextAlign.end => width - p.width,
        _ => 0,
      };
    }

    painter.paint(canvas, offset + Offset(dx(painter), 0));
    subPainter?.paint(canvas, offset + Offset(dx(subPainter!), painter.height + gap));
  }
}

TextStyle _font(bool rtl) => TextStyle(
  fontFamily: rtl ? 'StoreShotsArabic' : 'StoreShotsDisplay',
  fontFamilyFallback: const ['StoreShotsArabic', 'StoreShotsDisplay', 'StoreShotsSans'],
);

/// Builds the rich headline span (`*emphasis*` in the emphasis color).
TextSpan captionSpan(String raw, TemplateStyle style, double size, bool rtl) {
  final base = _font(rtl).copyWith(
    fontSize: size,
    fontWeight: style.weight,
    height: rtl ? 1.38 : 1.12,
    letterSpacing: rtl ? 0 : -size * 0.025,
    color: style.caption,
  );
  return TextSpan(
    style: base,
    children: [
      for (final s in parseCaption(raw))
        TextSpan(text: s.text, style: s.emphasis ? TextStyle(color: style.emphasis) : null),
    ],
  );
}

/// Draws one store image for [scene] at [size].
class ShotComposer extends StatelessWidget {
  /// Creates the composer.
  const ShotComposer({super.key, required this.scene, required this.size});

  /// What to draw.
  final ShotScene scene;

  /// Output size in logical pixels (= pixels, rendered at ratio 1).
  final Size size;

  @override
  Widget build(BuildContext context) {
    final st = scene.style;
    final w = size.width, h = size.height;
    final tablet = scene.device.tablet;
    final sidePad = w * (tablet ? 0.1 : 0.075);
    final topPad = h * (tablet ? 0.055 : 0.065);
    final baseSize = w * (tablet ? 0.058 : 0.083);
    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: BackdropPainter(
            kind: st.backdrop,
            colors: st.colors,
            accent: st.accent,
            seed: scene.index,
            glowAt: const Offset(0.5, 0.64),
          ),
        ),
      ),
    ];

    DeviceFrame frameFor(int i, {bool highlight = true, bool shadow = true}) => DeviceFrame(
      shot: scene.shots[i],
      device: scene.device,
      frame: scene.frame,
      statusBar: scene.config.statusBar,
      framed: scene.config.frame,
      accent: st.accent,
      drawHighlight: highlight,
      shadow: shadow,
      textDirection: scene.direction,
    );

    final main = frameFor(scene.index);
    final aspect = main.aspectRatio;

    CaptionLayout caption({double? maxWidth, TextAlign? align, int maxLines = 3, double factor = 1}) =>
        CaptionLayout.measure(
          headline: scene.headline,
          subtitle: scene.subtitle,
          style: st,
          maxWidth: maxWidth ?? w - sidePad * 2,
          baseSize: baseSize * factor,
          rtl: scene.rtl,
          maxLines: maxLines,
          align: align,
        );

    Widget captionAt(CaptionLayout c, Offset at, double width, TextAlign align) => Positioned(
      left: at.dx,
      top: at.dy,
      width: width,
      height: c.height + 4,
      child: CustomPaint(painter: _CaptionPainter(c, align, scene.rtl)),
    );

    final hasCaption = scene.headline.trim().isNotEmpty;

    // Spotlight: the device is dimmed except the highlighted widget.
    Widget dimmedFrame(int i) {
      final sh = scene.shots[i];
      if (sh.highlight == null) return frameFor(i);
      return DeviceFrame(
        shot: ScreenShot(
          image: sh.image,
          logicalWidth: sh.logicalWidth,
          logicalHeight: sh.logicalHeight,
          darkTop: true,
          darkBottom: true,
          highlight: sh.highlight,
          highlightConfig: const HighlightConfig(key: '', style: HighlightStyle.spotlight),
        ),
        device: scene.device,
        frame: scene.frame,
        statusBar: scene.config.statusBar,
        framed: scene.config.frame,
        accent: st.accent,
        textDirection: scene.direction,
      );
    }

    switch (st.layout) {
      case TemplateLayout.classic:
      case TemplateLayout.playful:
      case TemplateLayout.glass:
      case TemplateLayout.spotlight:
        final c = caption();
        var y = topPad;
        if (hasCaption) {
          if (st.layout == TemplateLayout.glass) {
            final cardPad = w * 0.06;
            final cardW = w - sidePad * 2 + cardPad * 2 - w * 0.04;
            final c2 = caption(maxWidth: cardW - cardPad * 2);
            final cardH = c2.height + cardPad * 1.6;
            final left = (w - cardW) / 2;
            children.add(Positioned(
              left: left,
              top: y,
              width: cardW,
              height: cardH,
              child: _GlassCard(radius: w * 0.06),
            ));
            children.add(captionAt(c2, Offset(left + cardPad, y + cardPad * 0.8), cardW - cardPad * 2, TextAlign.center));
            y += cardH + h * 0.035;
          } else {
            children.add(captionAt(c, Offset(sidePad, y), w - sidePad * 2, st.align));
            y += c.height + h * 0.04;
          }
        }
        final spotlight = st.layout == TemplateLayout.spotlight;
        final maxDW = w * (tablet ? 0.8 : (spotlight ? 0.74 : 0.8));
        final maxDH = h - y - h * 0.03;
        final fit = fitAspect(aspect, maxDW, maxDH);
        final dx = (w - fit.width) / 2;
        final angle = st.layout == TemplateLayout.playful ? (scene.rtl ? 1 : -1) * (scene.index.isEven ? 0.06 : -0.045) : 0.0;
        children.add(Positioned(
          left: dx,
          top: y,
          width: fit.width,
          height: fit.height,
          child: Transform.rotate(angle: angle, child: spotlight ? dimmedFrame(scene.index) : main),
        ));
        if (spotlight && scene.shot.highlight != null) {
          children.addAll(_spotlightCallout(Rect.fromLTWH(dx, y, fit.width, fit.height), main, w));
        }
      case TemplateLayout.bold:
        final c = caption(maxLines: 3);
        if (hasCaption) children.add(captionAt(c, Offset(sidePad, topPad * 1.1), w - sidePad * 2, TextAlign.start));
        final y = topPad * 1.1 + (hasCaption ? c.height + h * 0.045 : 0);
        final dw = w * (tablet ? 0.8 : 0.86);
        final dh = dw / aspect;
        children.add(Positioned(
          left: (w - dw) / 2,
          top: math.min(y, h - dh * 0.72),
          width: dw,
          height: dh,
          child: main,
        ));
      case TemplateLayout.tilted:
        final c = caption(maxWidth: w - sidePad * 2);
        if (hasCaption) children.add(captionAt(c, Offset(sidePad, topPad), w - sidePad * 2, TextAlign.start));
        final y = topPad + (hasCaption ? c.height + h * 0.075 : h * 0.03);
        final dw = w * (tablet ? 0.66 : 0.74);
        final dh = dw / aspect;
        final dir = scene.rtl ? -1.0 : 1.0;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.45 / dw)
          ..rotateX(0.12)
          ..rotateY(-0.42 * dir)
          ..rotateZ(0.05 * dir);
        children.add(Positioned(
          left: (w - dw) / 2 + w * 0.05 * dir,
          top: y,
          width: dw,
          height: dh,
          child: Transform(alignment: Alignment.topCenter, transform: m, child: main),
        ));
      case TemplateLayout.duo:
        final c = caption();
        var y = topPad;
        if (hasCaption) {
          children.add(captionAt(c, Offset(sidePad, y), w - sidePad * 2, TextAlign.center));
          y += c.height + h * 0.045;
        }
        final next = (scene.index + 1) % scene.shots.length;
        final maxDH = h - y - h * 0.02;
        final front = fitAspect(aspect, w * 0.7, maxDH);
        y += (maxDH - front.height) * 0.7;
        final back = (width: front.width * 0.88, height: front.height * 0.88);
        final dir = scene.rtl ? -1.0 : 1.0;
        final frontLeft = scene.rtl ? w - front.width - w * 0.06 : w * 0.06;
        final backLeft = scene.rtl ? w * 0.04 : w - back.width - w * 0.04;
        children.add(Positioned(
          left: backLeft,
          top: y + h * 0.05,
          width: back.width,
          height: back.height,
          child: Transform.rotate(angle: 0.08 * dir, child: Opacity(opacity: 0.96, child: frameFor(next, highlight: false))),
        ));
        children.add(Positioned(
          left: frontLeft,
          top: y,
          width: front.width,
          height: front.height,
          child: Transform.rotate(angle: -0.03 * dir, child: main),
        ));
      case TemplateLayout.panorama:
        // Rendered by PanoramaComposer; a single panel falls back to classic.
        final c = caption();
        if (hasCaption) children.add(captionAt(c, Offset(sidePad, topPad), w - sidePad * 2, st.align));
        final y = topPad + c.height + h * 0.04;
        final fit = fitAspect(aspect, w * 0.8, h - y - h * 0.03);
        children.add(Positioned(left: (w - fit.width) / 2, top: y, width: fit.width, height: fit.height, child: main));
    }

    return Directionality(
      textDirection: scene.direction,
      child: SizedBox(width: w, height: h, child: Stack(clipBehavior: Clip.hardEdge, children: children)),
    );
  }

  List<Widget> _spotlightCallout(Rect deviceRect, DeviceFrame frame, double w) {
    final shot = scene.shot;
    final g = frame.geometry;
    final k = deviceRect.width / g.outerWidth;
    final hl = shot.highlight!;
    final onDevice = Rect.fromLTWH(
      deviceRect.left + (g.screen.left + hl.left) * k,
      deviceRect.top + (g.screen.top + hl.top) * k,
      hl.width * k,
      hl.height * k,
    );
    // Crop area around the widget in screen-logical units.
    final crop = hl.inflate(shot.logicalWidth * 0.04);
    final cropRect = Rect.fromLTRB(
      math.max(0, crop.left),
      math.max(0, crop.top),
      math.min(shot.logicalWidth, crop.right),
      math.min(shot.logicalHeight, crop.bottom),
    );
    var calloutW = w * 0.86;
    var calloutH = calloutW * cropRect.height / cropRect.width;
    if (calloutH > w * 0.75) {
      calloutH = w * 0.75;
      calloutW = calloutH * cropRect.width / cropRect.height;
    }
    final left = (w - calloutW) / 2;
    // Float the zoom above the widget when there is room, else below it.
    final above = onDevice.top - deviceRect.top > calloutH + w * 0.2;
    final top = above ? onDevice.top - calloutH - w * 0.12 : onDevice.bottom + w * 0.12;
    final callout = Rect.fromLTWH(left, top, calloutW, calloutH);
    final label = shot.highlightLabel;
    return [
      Positioned.fill(child: CustomPaint(painter: _ConnectorPainter(onDevice, callout, scene.style.accent))),
      Positioned.fromRect(
        rect: callout,
        child: CustomPaint(
          painter: _ZoomPainter(shot.image, cropRect, shot.logicalWidth, scene.style.accent, w),
        ),
      ),
      if (label != null && label.isNotEmpty)
        Positioned(
          left: 0,
          width: w,
          top: above ? callout.top - w * 0.11 : callout.bottom + w * 0.035,
          height: w * 0.1,
          child: CustomPaint(painter: _LabelPainter(label, scene.style, w, scene.rtl)),
        ),
    ];
  }
}

class _CaptionPainter extends CustomPainter {
  _CaptionPainter(this.c, this.align, this.rtl);
  final CaptionLayout c;
  final TextAlign align;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) => c.paint(canvas, Offset.zero, size.width, align, rtl);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: radius * 0.6, sigmaY: radius * 0.6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x40FFFFFF), Color(0x14FFFFFF)],
          ),
          border: Border.all(color: const Color(0x66FFFFFF), width: radius * 0.04),
        ),
      ),
    ),
  );
}

class _ZoomPainter extends CustomPainter {
  _ZoomPainter(this.image, this.crop, this.logicalWidth, this.accent, this.w);
  final ui.Image image;
  final Rect crop;
  final double logicalWidth;
  final Color accent;
  final double w;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.035));
    canvas.drawRRect(r.shift(Offset(0, w * 0.02)), Paint()
      ..color = const Color(0x88000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04));
    canvas.save();
    canvas.clipRRect(r);
    final px = image.width / logicalWidth;
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(crop.left * px, crop.top * px, crop.right * px, crop.bottom * px),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.008
      ..color = accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.from, this.to, this.accent);
  final Rect from;
  final Rect to;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.006
      ..color = accent;
    canvas.drawRRect(RRect.fromRectAndRadius(from.inflate(w * 0.008), Radius.circular(w * 0.015)), glow);
    final below = to.top > from.bottom;
    final a = Offset(from.center.dx, below ? from.bottom + w * 0.01 : from.top - w * 0.01);
    final b = Offset(to.center.dx, below ? to.top : to.bottom);
    final dash = Paint()
      ..strokeWidth = w * 0.005
      ..color = accent.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round;
    final n = ((b - a).distance / (w * 0.018)).floor();
    for (var i = 0; i < n; i += 2) {
      canvas.drawLine(Offset.lerp(a, b, i / n)!, Offset.lerp(a, b, (i + 1) / n)!, dash);
    }
    canvas.drawCircle(a, w * 0.009, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LabelPainter extends CustomPainter {
  _LabelPainter(this.text, this.style, this.w, this.rtl);
  final String text;
  final TemplateStyle style;
  final double w;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: _font(rtl).copyWith(fontSize: w * 0.038, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
      ),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: size.width - w * 0.08);
    final pw = tp.width + w * 0.07;
    final ph = tp.height + w * 0.03;
    final left = (size.width - pw) / 2;
    final r = RRect.fromLTRBR(left, 0, left + pw, ph, Radius.circular(ph / 2));
    canvas.drawRRect(r, Paint()..color = style.accent);
    tp.paint(canvas, Offset(left + (pw - tp.width) / 2, (ph - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Draws the whole panorama: one wide scene, later sliced per screen.
class PanoramaComposer extends StatelessWidget {
  /// Creates the composer.
  const PanoramaComposer({super.key, required this.scenes, required this.panel});

  /// One scene per screen (same style/device/locale).
  final List<ShotScene> scenes;

  /// Size of one panel.
  final Size panel;

  @override
  Widget build(BuildContext context) {
    final first = scenes.first;
    final st = first.style;
    final n = scenes.length;
    final w = panel.width, h = panel.height;
    final tablet = first.device.tablet;
    final rtl = first.rtl;
    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(painter: _PanoramaBackdrop(st, n, rtl)),
      ),
    ];
    for (var i = 0; i < n; i++) {
      final s = scenes[i];
      // Visual order: in RTL the first screen sits on the right.
      final slot = rtl ? n - 1 - i : i;
      final x0 = slot * w;
      final sidePad = w * 0.075;
      final c = CaptionLayout.measure(
        headline: s.headline,
        subtitle: s.subtitle,
        style: st,
        maxWidth: w - sidePad * 2,
        baseSize: w * (tablet ? 0.058 : 0.083),
        rtl: rtl,
      );
      final topPad = h * 0.065;
      if (s.headline.trim().isNotEmpty) {
        children.add(Positioned(
          left: x0 + sidePad,
          top: topPad,
          width: w - sidePad * 2,
          height: c.height + 4,
          child: CustomPaint(painter: _CaptionPainter(c, TextAlign.center, rtl)),
        ));
      }
      final frame = DeviceFrame(
        shot: s.shot,
        device: s.device,
        frame: s.frame,
        statusBar: s.config.statusBar,
        framed: s.config.frame,
        accent: st.accent,
        textDirection: s.direction,
      );
      final y = topPad + c.height + h * 0.045;
      final fit = fitAspect(frame.aspectRatio, w * 0.78, h - y - h * 0.03);
      // Every other device slides toward the seam so it spans two images.
      final drift = (i.isOdd ? 0.2 : -0.06) * w * (rtl ? -1 : 1);
      final angle = (i.isOdd ? 0.07 : -0.035) * (rtl ? -1 : 1);
      final shift = i == n - 1 && i.isOdd ? 0.0 : drift;
      children.add(Positioned(
        left: x0 + (w - fit.width) / 2 + shift,
        top: y + (i.isOdd ? h * 0.03 : 0),
        width: fit.width,
        height: fit.height,
        child: Transform.rotate(angle: angle, child: frame),
      ));
    }
    return Directionality(
      textDirection: first.direction,
      child: SizedBox(width: w * n, height: h, child: Stack(clipBehavior: Clip.hardEdge, children: children)),
    );
  }
}

class _PanoramaBackdrop extends CustomPainter {
  _PanoramaBackdrop(this.style, this.panels, this.rtl);
  final TemplateStyle style;
  final int panels;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = style.colors;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rtl ? rect.topRight : rect.topLeft,
          rtl ? rect.bottomLeft : rect.bottomRight,
          colors.length > 1 ? colors : [colors.first, colors.first],
          colors.length > 1 ? [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)] : null,
        ),
    );
    final w = size.width, h = size.height;
    final pw = w / panels;
    // A flowing ribbon across all panels.
    final ribbon = Path()..moveTo(0, h * 0.62);
    for (var x = 0.0; x <= w; x += pw / 40) {
      ribbon.lineTo(x, h * (0.62 + 0.14 * math.sin(x / pw * math.pi * 1.25 + 0.6)));
    }
    canvas.drawPath(
      ribbon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pw * 0.34
        ..color = const Color(0x17FFFFFF)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      ribbon.shift(Offset(0, h * 0.09)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pw * 0.014
        ..color = style.accent.withValues(alpha: 0.85)
        ..strokeCap = StrokeCap.round,
    );
    // Soft orbs on the seams.
    for (var i = 1; i < panels; i++) {
      final c = Offset(i * pw, h * (i.isEven ? 0.3 : 0.78));
      canvas.drawCircle(
        c,
        pw * 0.45,
        Paint()
          ..shader = ui.Gradient.radial(c, pw * 0.45, [const Color(0x40FFFFFF), const Color(0x00FFFFFF)]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
