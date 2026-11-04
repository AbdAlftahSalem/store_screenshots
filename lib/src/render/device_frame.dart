import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/catalog.dart';
import '../core/config.dart';
import '../core/devices.dart';
import '../core/geometry.dart';

/// Everything needed to draw one framed (or frameless) screen.
class ScreenShot {
  /// Creates a captured screen.
  const ScreenShot({
    required this.image,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.darkTop,
    required this.darkBottom,
    this.highlight,
    this.highlightConfig,
    this.highlightLabel,
  });

  /// The app as rendered, at device pixel ratio.
  final ui.Image image;

  /// Logical width the app was rendered at.
  final double logicalWidth;

  /// Logical height the app was rendered at.
  final double logicalHeight;

  /// Whether the top of the screen is dark (→ light status bar icons).
  final bool darkTop;

  /// Whether the bottom of the screen is dark (→ light home indicator).
  final bool darkBottom;

  /// Highlighted widget rect in logical screen coordinates.
  final Rect? highlight;

  /// Highlight settings.
  final HighlightConfig? highlightConfig;

  /// Resolved highlight label text.
  final String? highlightLabel;
}

/// Draws a device frame (in Dart, no image assets) around a screenshot,
/// with a mocked status bar and an optional highlight.
class DeviceFrame extends StatelessWidget {
  /// Creates a device frame.
  const DeviceFrame({
    super.key,
    required this.shot,
    required this.device,
    required this.frame,
    required this.statusBar,
    required this.framed,
    this.accent = const Color(0xFF7C3AED),
    this.shadow = true,
    this.drawHighlight = true,
    this.textDirection = TextDirection.ltr,
    this.rounded = true,
  });

  /// Round the screen corners when there is no frame.
  final bool rounded;

  /// The captured screen.
  final ScreenShot shot;

  /// Store device.
  final DeviceSpec device;

  /// Frame model and finish.
  final FrameChoice frame;

  /// Status bar settings.
  final StatusBarConfig statusBar;

  /// Draw the frame (false = just the rounded screen).
  final bool framed;

  /// Accent color for highlights.
  final Color accent;

  /// Draw a soft drop shadow.
  final bool shadow;

  /// Draw the highlight ring/arrow.
  final bool drawHighlight;

  /// Direction (for the highlight label).
  final TextDirection textDirection;

  /// Aspect ratio of the frame.
  double get aspectRatio => geometry.aspectRatio;

  /// Frame geometry in screen-logical units.
  FrameGeometry get geometry => framed
      ? frameGeometry(frame.model, shot.logicalWidth, shot.logicalHeight)
      : FrameGeometry(
          outerWidth: shot.logicalWidth,
          outerHeight: shot.logicalHeight,
          bezel: 0,
          rail: 0,
          outerRadius: rounded ? shot.logicalWidth * 0.08 : 0,
          screen: Box(0, 0, shot.logicalWidth, shot.logicalHeight),
          screenRadius: rounded ? shot.logicalWidth * 0.08 : 0,
        );

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: CustomPaint(
      painter: DeviceFramePainter(
        shot: shot,
        device: device,
        frame: frame,
        statusBar: statusBar,
        geometry: geometry,
        framed: framed,
        accent: accent,
        shadow: shadow,
        drawHighlight: drawHighlight,
        textDirection: textDirection,
      ),
    ),
  );
}

/// Paints [DeviceFrame].
class DeviceFramePainter extends CustomPainter {
  /// Creates the painter.
  DeviceFramePainter({
    required this.shot,
    required this.device,
    required this.frame,
    required this.statusBar,
    required this.geometry,
    required this.framed,
    required this.accent,
    required this.shadow,
    required this.drawHighlight,
    required this.textDirection,
  });

  /// See [DeviceFrame.shot].
  final ScreenShot shot;

  /// See [DeviceFrame.device].
  final DeviceSpec device;

  /// See [DeviceFrame.frame].
  final FrameChoice frame;

  /// See [DeviceFrame.statusBar].
  final StatusBarConfig statusBar;

  /// Frame geometry.
  final FrameGeometry geometry;

  /// See [DeviceFrame.framed].
  final bool framed;

  /// See [DeviceFrame.accent].
  final Color accent;

  /// See [DeviceFrame.shadow].
  final bool shadow;

  /// See [DeviceFrame.drawHighlight].
  final bool drawHighlight;

  /// See [DeviceFrame.textDirection].
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final s = size.width / g.outerWidth;
    canvas.save();
    canvas.scale(s);
    final outer = RRect.fromLTRBR(0, 0, g.outerWidth, g.outerHeight, Radius.circular(g.outerRadius));
    final finish = frame.finish;
    final body = Color(finish.body);
    final edge = Color(finish.edge);
    final sw = shot.logicalWidth;

    if (shadow) {
      final blur = g.outerWidth * 0.06;
      canvas.drawRRect(
        outer.shift(Offset(0, g.outerWidth * 0.045)),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
      canvas.drawRRect(
        outer.shift(Offset(0, g.outerWidth * 0.012)),
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur * 0.25),
      );
    }

    if (framed) {
      _buttons(canvas, g, Color(finish.button), edge);
      // Metal rail with a light edge on top-left and a darker one bottom-right.
      canvas.drawRRect(
        outer,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(g.outerWidth, g.outerHeight), [
            _mix(edge, body, 0.2),
            body,
            _mix(body, const Color(0xFF000000), 0.25),
          ], [0, 0.55, 1]),
      );
      if (frame.model.flatEdges) {
        canvas.drawRRect(
          outer.deflate(g.rail * 0.45),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = g.rail * 0.18
            ..color = edge.withValues(alpha: 0.55),
        );
      }
      canvas.drawRRect(
        outer.deflate(g.rail * 0.08),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.rail * 0.16
          ..color = const Color(0x22FFFFFF),
      );
      // Black glass bezel.
      final glass = outer.deflate(g.rail);
      canvas.drawRRect(glass, Paint()..color = const Color(0xFF050506));
    }

    // Screen.
    final screenRect = Rect.fromLTWH(g.screen.left, g.screen.top, g.screen.width, g.screen.height);
    final screen = RRect.fromRectAndRadius(screenRect, Radius.circular(g.screenRadius));
    canvas.save();
    canvas.clipRRect(screen);
    canvas.drawImageRect(
      shot.image,
      Rect.fromLTWH(0, 0, shot.image.width.toDouble(), shot.image.height.toDouble()),
      screenRect,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
    canvas.translate(screenRect.left, screenRect.top);
    if (statusBar.enabled) _statusBar(canvas, sw);
    _homeIndicator(canvas, sw, shot.logicalHeight);
    if (drawHighlight && shot.highlight != null) {
      paintHighlight(canvas, shot.highlight!, shot.highlightConfig?.style ?? HighlightStyle.ring, accent,
          Size(sw, shot.logicalHeight), label: shot.highlightLabel, textDirection: textDirection);
    }
    canvas.restore();

    if (framed) {
      _cutout(canvas, g, sw);
      // Very subtle glass reflection.
      canvas.save();
      canvas.clipRRect(screen);
      final p = Path()
        ..moveTo(screenRect.left, screenRect.top)
        ..lineTo(screenRect.left + screenRect.width * 0.62, screenRect.top)
        ..lineTo(screenRect.left, screenRect.top + screenRect.height * 0.42)
        ..close();
      canvas.drawPath(
        p,
        Paint()
          ..shader = ui.Gradient.linear(screenRect.topLeft, screenRect.topLeft + Offset(sw * 0.4, sw * 0.4), [
            const Color(0x0FFFFFFF),
            const Color(0x00FFFFFF),
          ]),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _buttons(Canvas canvas, FrameGeometry g, Color color, Color edge) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(g.outerWidth, 0), [_mix(edge, color, 0.4), color]);
    final w = g.outerWidth;
    final t = w * 0.012;
    void left(double top, double len) => canvas.drawRRect(
      RRect.fromLTRBR(-t, top, t, top + len, Radius.circular(t)),
      paint,
    );
    void right(double top, double len) => canvas.drawRRect(
      RRect.fromLTRBR(w - t, top, w + t, top + len, Radius.circular(t)),
      paint,
    );
    switch (frame.model.shape) {
      case FrameShape.island:
        left(w * 0.36, w * 0.07);
        left(w * 0.50, w * 0.13);
        left(w * 0.67, w * 0.13);
        right(w * 0.55, w * 0.2);
        right(g.outerHeight * 0.62, w * 0.1);
      case FrameShape.punchHole:
        right(w * 0.45, w * 0.24);
        right(w * 0.78, w * 0.12);
      case FrameShape.tablet:
        right(w * 0.06, w * 0.06);
        right(w * 0.14, w * 0.06);
        canvas.drawRRect(RRect.fromLTRBR(w * 0.8, -t, w * 0.9, t, Radius.circular(t)), paint);
    }
  }

  void _cutout(Canvas canvas, FrameGeometry g, double sw) {
    final cx = g.outerWidth / 2;
    final black = Paint()..color = const Color(0xFF000000);
    switch (frame.model.shape) {
      case FrameShape.island:
        final iw = sw * 0.285 * frame.model.cutoutScale;
        final ih = sw * 0.084 * frame.model.cutoutScale;
        final top = g.screen.top + sw * 0.026;
        final r = RRect.fromLTRBR(cx - iw / 2, top, cx + iw / 2, top + ih, Radius.circular(ih / 2));
        canvas.drawRRect(r, black);
        _lens(canvas, Offset(cx + iw / 2 - ih / 2, top + ih / 2), ih * 0.3);
      case FrameShape.punchHole:
        final d = sw * 0.03 * frame.model.cutoutScale;
        final c = Offset(cx, g.screen.top + sw * 0.03 + d / 2);
        canvas.drawCircle(c, d / 2, black);
        _lens(canvas, c, d * 0.28);
      case FrameShape.tablet:
        final c = Offset(cx, g.rail + (g.screen.top - g.rail) / 2);
        canvas.drawCircle(c, g.bezel * 0.18, Paint()..color = const Color(0xFF1A1C22));
        _lens(canvas, c, g.bezel * 0.1);
    }
  }

  void _lens(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c - Offset(r * 0.3, r * 0.3), r * 1.4, [
          const Color(0xFF2B3A5C),
          const Color(0xFF0B0F1A),
        ]),
    );
    canvas.drawCircle(c - Offset(r * 0.35, r * 0.35), r * 0.25, Paint()..color = const Color(0x55FFFFFF));
  }

  void _statusBar(Canvas canvas, double sw) {
    final ios = device.store == Store.ios;
    final color = shot.darkTop ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final h = device.statusBarHeight;
    final scale = sw / (device.tablet ? 700 : 400);
    if (ios && !device.tablet) {
      // Left ear: the time, centered between the corner and the island.
      final islandLeft = sw / 2 - sw * 0.285 / 2;
      final tp = _text(statusBar.time, 17 * scale, FontWeight.w600, color);
      final cy = sw * 0.026 + sw * 0.042;
      tp.paint(canvas, Offset((islandLeft - tp.width) / 2 + sw * 0.01, cy - tp.height / 2));
      // Right ear: signal, wifi, battery.
      final islandRight = sw / 2 + sw * 0.285 / 2;
      final iconsW = 76 * scale;
      final x = islandRight + (sw - islandRight - iconsW) / 2 - sw * 0.005;
      _signal(canvas, Offset(x, cy + 6 * scale), 17 * scale, 11 * scale, color);
      _wifi(canvas, Offset(x + 30 * scale, cy + 5.5 * scale), 8.5 * scale, color);
      _battery(canvas, Offset(x + 47 * scale, cy - 6.5 * scale), 27 * scale, 13 * scale, color, horizontal: true);
    } else {
      final pad = (ios ? 22 : 18) * scale;
      final cy = h * (ios ? 0.5 : 0.52);
      final tp = _text(statusBar.time, (ios ? 15 : 14.5) * scale, FontWeight.w500, color);
      tp.paint(canvas, Offset(pad + (ios ? 0 : 6 * scale), cy - tp.height / 2));
      var x = sw - pad;
      if (ios) {
        x -= 26 * scale;
        _battery(canvas, Offset(x, cy - 6 * scale), 25 * scale, 12 * scale, color, horizontal: true);
        x -= 22 * scale;
        _wifi(canvas, Offset(x + 8 * scale, cy + 5 * scale), 8 * scale, color);
        x -= 24 * scale;
        _signal(canvas, Offset(x, cy + 5 * scale), 17 * scale, 10 * scale, color);
      } else {
        x -= 8 * scale;
        _battery(canvas, Offset(x, cy - 7.5 * scale), 8 * scale, 15 * scale, color, horizontal: false);
        x -= 20 * scale;
        _cellTriangle(canvas, Offset(x, cy + 7 * scale), 14 * scale, color);
        x -= 12 * scale;
        _wifiFilled(canvas, Offset(x, cy + 6 * scale), 9 * scale, color);
      }
    }
  }

  void _homeIndicator(Canvas canvas, double sw, double sh) {
    final ios = device.store == Store.ios;
    final color = shot.darkBottom ? const Color(0xEEFFFFFF) : const Color(0xE6000000);
    final scale = sw / (device.tablet ? 700 : 400);
    final w = ios ? (device.tablet ? 210 : 136) * scale : 108 * scale;
    final h = ios ? 5 * scale : 4.5 * scale;
    final bottom = sh - (ios ? 8 * scale : 9 * scale);
    canvas.drawRRect(
      RRect.fromLTRBR(sw / 2 - w / 2, bottom - h, sw / 2 + w / 2, bottom, Radius.circular(h / 2)),
      Paint()..color = color,
    );
  }

  TextPainter _text(String text, double size, FontWeight weight, Color color) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'StoreShotsSans', fontSize: size, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  void _signal(Canvas canvas, Offset bottomLeft, double w, double h, Color c) {
    final bw = w / 4 - w * 0.06;
    for (var i = 0; i < 4; i++) {
      final bh = h * (0.4 + 0.2 * i);
      final x = bottomLeft.dx + i * (w / 4);
      canvas.drawRRect(
        RRect.fromLTRBR(x, bottomLeft.dy - bh, x + bw, bottomLeft.dy, Radius.circular(bw * 0.3)),
        Paint()..color = c,
      );
    }
  }

  void _wifi(Canvas canvas, Offset bottomCenter, double r, Color c) {
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 2; i++) {
      final rr = r * (0.42 + 0.48 * i);
      canvas.drawArc(Rect.fromCircle(center: bottomCenter, radius: rr), -math.pi * 0.75, math.pi * 0.5, false, p);
    }
    canvas.drawCircle(bottomCenter - Offset(0, r * 0.22), r * 0.2, Paint()..color = c);
  }

  void _wifiFilled(Canvas canvas, Offset bottomCenter, double r, Color c) {
    final path = Path()
      ..moveTo(bottomCenter.dx, bottomCenter.dy)
      ..arcTo(Rect.fromCircle(center: bottomCenter, radius: r * 1.4), -math.pi * 0.78, math.pi * 0.56, false)
      ..close();
    canvas.drawPath(path, Paint()..color = c);
  }

  void _cellTriangle(Canvas canvas, Offset bottomLeft, double s, Color c) {
    final path = Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomLeft.dx + s, bottomLeft.dy)
      ..lineTo(bottomLeft.dx + s, bottomLeft.dy - s)
      ..close();
    canvas.drawPath(path, Paint()..color = c);
  }

  void _battery(Canvas canvas, Offset topLeft, double w, double h, Color c, {required bool horizontal}) {
    final level = statusBar.battery / 100;
    if (horizontal) {
      final body = RRect.fromLTRBR(topLeft.dx, topLeft.dy, topLeft.dx + w - w * 0.08, topLeft.dy + h,
          Radius.circular(h * 0.3));
      canvas.drawRRect(body, Paint()
        ..color = c.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.09);
      final inner = body.deflate(h * 0.16);
      canvas.drawRRect(
        RRect.fromLTRBR(inner.left, inner.top, inner.left + inner.width * level, inner.bottom,
            Radius.circular(h * 0.18)),
        Paint()..color = c,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(body.right + w * 0.02, topLeft.dy + h * 0.32, body.right + w * 0.08,
            topLeft.dy + h * 0.68, Radius.circular(w * 0.03)),
        Paint()..color = c.withValues(alpha: 0.45),
      );
    } else {
      final body = RRect.fromLTRBR(topLeft.dx, topLeft.dy + h * 0.1, topLeft.dx + w, topLeft.dy + h,
          Radius.circular(w * 0.18));
      canvas.drawRRect(
        RRect.fromLTRBR(topLeft.dx + w * 0.3, topLeft.dy, topLeft.dx + w * 0.7, topLeft.dy + h * 0.12,
            Radius.circular(w * 0.1)),
        Paint()..color = c,
      );
      canvas.drawRRect(body, Paint()..color = c.withValues(alpha: level >= 1 ? 1 : 0.35));
      if (level < 1) {
        final top = body.bottom - body.height * level;
        canvas.drawRRect(
          RRect.fromLTRBR(body.left, top, body.right, body.bottom, Radius.circular(w * 0.18)),
          Paint()..color = c,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DeviceFramePainter old) => true;
}

/// Draws a highlight (ring / arrow / spotlight) around [rect] in screen
/// coordinates.
void paintHighlight(
  Canvas canvas,
  Rect rect,
  HighlightStyle style,
  Color accent,
  Size screen, {
  String? label,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final pad = screen.width * 0.018;
  final r = rect.inflate(pad);
  final radius = Radius.circular(math.min(r.shortestSide / 2, screen.width * 0.05));
  final rr = RRect.fromRectAndRadius(r, radius);
  switch (style) {
    case HighlightStyle.spotlight:
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & screen)
        ..addRRect(rr);
      canvas.drawPath(path, Paint()..color = const Color(0x99000000));
      canvas.drawRRect(rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = screen.width * 0.007
        ..color = const Color(0xFFFFFFFF));
    case HighlightStyle.ring:
    case HighlightStyle.arrow:
      canvas.drawRRect(rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = screen.width * 0.03
        ..color = accent.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, screen.width * 0.012));
      canvas.drawRRect(rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = screen.width * 0.009
        ..color = accent);
      if (style == HighlightStyle.arrow) {
        // Curved arrow coming from above (or below when there is no room).
        final fromAbove = r.top > screen.height * 0.25;
        final rtl = textDirection == TextDirection.rtl;
        final tip = Offset(r.center.dx + (rtl ? r.width * 0.2 : -r.width * 0.2), fromAbove ? r.top - pad * 0.6 : r.bottom + pad * 0.6);
        final start = tip + Offset(rtl ? -screen.width * 0.18 : screen.width * 0.18, fromAbove ? -screen.width * 0.26 : screen.width * 0.26);
        final ctrl = Offset(start.dx, tip.dy);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = screen.width * 0.011
          ..strokeCap = StrokeCap.round
          ..color = accent;
        canvas.drawPath(Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy), paint);
        final dir = (tip - ctrl);
        final ang = math.atan2(dir.dy, dir.dx);
        final hl = screen.width * 0.045;
        canvas.drawPath(Path()
          ..moveTo(tip.dx + hl * math.cos(ang + 2.6), tip.dy + hl * math.sin(ang + 2.6))
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(tip.dx + hl * math.cos(ang - 2.6), tip.dy + hl * math.sin(ang - 2.6)), paint);
        if (label != null && label.isNotEmpty) {
          _pill(canvas, label, start + Offset(0, fromAbove ? -screen.width * 0.05 : screen.width * 0.05), accent,
              screen.width, textDirection);
        }
        return;
      }
  }
  if (label != null && label.isNotEmpty) {
    final above = r.top > screen.height * 0.2;
    _pill(canvas, label, Offset(r.center.dx, above ? r.top - screen.width * 0.07 : r.bottom + screen.width * 0.07),
        accent, screen.width, textDirection);
  }
}

void _pill(Canvas canvas, String text, Offset center, Color accent, double sw, TextDirection dir) {
  final rtl = dir == TextDirection.rtl;
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: rtl ? 'StoreShotsArabic' : 'StoreShotsDisplay',
        fontFamilyFallback: const ['StoreShotsArabic', 'StoreShotsSans'],
        fontSize: sw * 0.042,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
      ),
    ),
    textDirection: dir,
  )..layout(maxWidth: sw * 0.8);
  final w = tp.width + sw * 0.07;
  final h = tp.height + sw * 0.035;
  var left = center.dx - w / 2;
  left = left.clamp(sw * 0.03, sw * 0.97 - w).toDouble();
  final r = RRect.fromLTRBR(left, center.dy - h / 2, left + w, center.dy + h / 2, Radius.circular(h / 2));
  canvas.drawRRect(r.shift(Offset(0, sw * 0.008)), Paint()
    ..color = const Color(0x44000000)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sw * 0.012));
  canvas.drawRRect(r, Paint()..color = accent);
  tp.paint(canvas, Offset(left + (w - tp.width) / 2, center.dy - tp.height / 2));
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
