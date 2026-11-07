import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Background kinds used by the templates.
enum BackdropKind {
  /// Deep gradient with glowing aurora blobs.
  aurora,

  /// Soft light vertical gradient.
  clean,

  /// Near-black with a neon glow and faint grid.
  midnight,

  /// Plain linear gradient with soft light streaks.
  gradient,

  /// Solid color with big subtle rings.
  solid,

  /// Multi-color mesh gradient.
  mesh,

  /// Dark stage with a light beam from the top.
  stage,

  /// Cream with pastel blobs and playful shapes.
  pastel,
}

/// Paints a template background. [seed] varies blob positions per screen so
/// a set of screenshots does not look copy-pasted.
class BackdropPainter extends CustomPainter {
  /// Creates the painter.
  BackdropPainter({required this.kind, required this.colors, required this.accent, this.seed = 0, this.glowAt});

  /// Background style.
  final BackdropKind kind;

  /// Base colors (1 = solid, 2+ = gradient).
  final List<Color> colors;

  /// Accent color used for glows.
  final Color accent;

  /// Variation seed (screen index).
  final int seed;

  /// Where to put the glow behind the device (fractions of the size).
  final Offset? glowAt;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width, h = size.height;
    final rnd = math.Random(seed * 7919 + kind.index * 31);
    double jitter(double v) => v + (rnd.nextDouble() - 0.5) * 0.18;
    void base() {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = colors.length == 1
              ? null
              : ui.Gradient.linear(rect.topLeft, rect.bottomRight, colors, _stops(colors.length))
          ..color = colors.first,
      );
    }

    void blob(Offset c, double r, Color color, [double opacity = 1]) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            r,
            [color.withValues(alpha: opacity), color.withValues(alpha: opacity * 0.45), color.withValues(alpha: 0)],
            const [0, 0.45, 1],
          ),
      );
    }

    switch (kind) {
      case BackdropKind.aurora:
        base();
        final palette = [const Color(0xFF22D3EE), const Color(0xFF8B5CF6), const Color(0xFFEC4899), accent];
        blob(Offset(w * jitter(0.15), h * jitter(0.12)), w * 0.75, palette[seed % 4], 0.55);
        blob(Offset(w * jitter(0.92), h * jitter(0.35)), w * 0.8, palette[(seed + 1) % 4], 0.5);
        blob(Offset(w * jitter(0.3), h * jitter(0.78)), w * 0.9, palette[(seed + 2) % 4], 0.42);
        blob(Offset(w * jitter(0.85), h * jitter(0.95)), w * 0.6, palette[(seed + 3) % 4], 0.35);
        _grain(canvas, size, 0.035);
      case BackdropKind.clean:
        base();
        blob(Offset(w * 0.5, h * 0.62), w * 0.75, const Color(0xFFFFFFFF), 0.85);
      case BackdropKind.midnight:
        base();
        _grid(canvas, size, const Color(0x0FFFFFFF));
        final g = glowAt ?? const Offset(0.5, 0.62);
        blob(Offset(w * g.dx, h * g.dy), w * 0.85, accent, 0.55);
        blob(Offset(w * g.dx, h * g.dy), w * 0.35, Color.lerp(accent, const Color(0xFFFFFFFF), 0.3)!, 0.35);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(Offset(0, h * 0.75), Offset(0, h), [
              const Color(0x00000000),
              const Color(0xAA000000),
            ]),
        );
      case BackdropKind.gradient:
        base();
        final streak = Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, h * 0.2),
            Offset(w, h * 0.6),
            [const Color(0x00FFFFFF), const Color(0x26FFFFFF), const Color(0x00FFFFFF)],
            const [0.2, 0.5, 0.8],
          );
        canvas.save();
        canvas.translate(w * 0.5, h * 0.5);
        canvas.rotate(-0.5 + seed * 0.08);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w * 3, height: h * 0.16), streak);
        canvas.drawRect(Rect.fromCenter(center: Offset(0, h * 0.22), width: w * 3, height: h * 0.05), streak);
        canvas.restore();
        blob(Offset(w * 0.5, h * 0.95), w * 0.9, const Color(0xFFFFFFFF), 0.12);
      case BackdropKind.solid:
        base();
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.09
          ..color = const Color(0x14FFFFFF);
        final c = Offset(w * (seed.isEven ? 1.05 : -0.05), h * 0.72);
        canvas.drawCircle(c, w * 0.55, ring);
        canvas.drawCircle(c, w * 0.9, ring..color = const Color(0x0DFFFFFF));
      case BackdropKind.mesh:
        base();
        final palette = colors.length >= 2
            ? [...colors, accent]
            : [const Color(0xFFFF7EB3), const Color(0xFF7AF5FF), const Color(0xFFFFC371), accent];
        blob(Offset(w * jitter(0.0), h * jitter(0.05)), w * 1.0, palette[seed % palette.length], 0.95);
        blob(Offset(w * jitter(1.0), h * jitter(0.3)), w * 0.95, palette[(seed + 1) % palette.length], 0.9);
        blob(Offset(w * jitter(0.1), h * jitter(0.7)), w * 1.0, palette[(seed + 2) % palette.length], 0.85);
        blob(Offset(w * jitter(0.95), h * jitter(1.0)), w * 0.9, palette[(seed + 3) % palette.length], 0.85);
        _grain(canvas, size, 0.03);
      case BackdropKind.stage:
        base();
        final beam = Path()
          ..moveTo(w * 0.38, -h * 0.02)
          ..lineTo(w * 0.62, -h * 0.02)
          ..lineTo(w * 1.05, h * 1.0)
          ..lineTo(-w * 0.05, h * 1.0)
          ..close();
        canvas.drawPath(
          beam,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, 0),
              Offset(0, h),
              [const Color(0x40BFD4FF), const Color(0x0FBFD4FF), const Color(0x00BFD4FF)],
              const [0, 0.55, 1],
            )
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
        );
        blob(Offset(w * 0.5, 0), w * 0.6, const Color(0xFFFFFFFF), 0.16);
        blob(Offset(w * 0.5, h * 0.98), w * 0.9, const Color(0xFF3B5BDB), 0.35);
      case BackdropKind.pastel:
        base();
        final palette = [
          const Color(0xFFFFC8DD),
          const Color(0xFFBDE0FE),
          const Color(0xFFCDEAC0),
          const Color(0xFFFFE5A5),
          const Color(0xFFD7C5F5),
        ];
        blob(Offset(w * jitter(0.05), h * jitter(0.25)), w * 0.7, palette[seed % 5], 1);
        blob(Offset(w * jitter(0.95), h * jitter(0.55)), w * 0.75, palette[(seed + 1) % 5], 1);
        blob(Offset(w * jitter(0.2), h * jitter(0.92)), w * 0.7, palette[(seed + 2) % 5], 1);
        // Playful shapes.
        final ink = Paint()
          ..color = accent.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012
          ..strokeCap = StrokeCap.round;
        final sq = Path();
        final y0 = h * (0.30 + rnd.nextDouble() * 0.05);
        final x0 = w * (seed.isEven ? 0.06 : 0.78);
        sq.moveTo(x0, y0);
        for (var i = 0; i < 4; i++) {
          sq.relativeQuadraticBezierTo(w * 0.02, -w * 0.035, w * 0.04, 0);
        }
        canvas.drawPath(sq, ink);
        _star(canvas, Offset(w * (seed.isEven ? 0.88 : 0.12), h * 0.47), w * 0.035, const Color(0xFFFFB703));
        canvas.drawCircle(
          Offset(w * (seed.isEven ? 0.1 : 0.9), h * 0.62),
          w * 0.022,
          Paint()..color = const Color(0xFFFB6F92),
        );
        canvas.drawCircle(
          Offset(w * (seed.isEven ? 0.92 : 0.08), h * 0.82),
          w * 0.03,
          Paint()
            ..color = const Color(0xFF4CC9F0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.01,
        );
    }
  }

  void _grain(Canvas canvas, Size size, double opacity) {
    // Cheap deterministic dither so big gradients do not band.
    final rnd = math.Random(42);
    final p = Paint()..strokeWidth = size.width * 0.0016;
    final pts = <Offset>[];
    final n = (size.width * size.height / 900).clamp(0, 9000).toInt();
    for (var i = 0; i < n; i++) {
      pts.add(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height));
    }
    p.color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawPoints(ui.PointMode.points, pts, p);
  }

  void _grid(Canvas canvas, Size size, Color color) {
    final step = size.width / 12;
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.0012;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * 0.38;
      final a = -math.pi / 2 + i * math.pi / 4;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  List<double> _stops(int n) => [for (var i = 0; i < n; i++) i / (n - 1)];

  @override
  bool shouldRepaint(covariant BackdropPainter old) => true;
}
