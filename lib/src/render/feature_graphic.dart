import 'package:flutter/widgets.dart';

import '../core/captions.dart';
import 'backdrops.dart';
import 'device_frame.dart';
import 'templates.dart';

/// Google Play Feature Graphic (1024×500): app name, tagline and two tilted
/// devices, in the template's look.
class FeatureGraphicComposer extends StatelessWidget {
  /// Creates the composer.
  const FeatureGraphicComposer({
    super.key,
    required this.scene,
    required this.appName,
    required this.tagline,
    this.size = const Size(1024, 500),
  });

  /// Scene carrying style, device, frame and captured screens.
  final ShotScene scene;

  /// App name.
  final String appName;

  /// Tagline (may contain `*emphasis*`).
  final String tagline;

  /// Output size.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final st = scene.style;
    final w = size.width, h = size.height;
    final rtl = scene.rtl;
    final textW = w * 0.5;
    final name = TextPainter(
      text: TextSpan(
        text: appName,
        style: TextStyle(
          fontFamily: rtl ? 'StoreShotsArabic' : 'StoreShotsDisplay',
          fontFamilyFallback: const ['StoreShotsArabic', 'StoreShotsDisplay'],
          fontSize: h * 0.15,
          fontWeight: FontWeight.w800,
          letterSpacing: rtl ? 0 : -h * 0.004,
          color: st.caption,
          height: 1.1,
        ),
      ),
      textDirection: scene.direction,
      maxLines: 2,
    )..layout(maxWidth: textW);
    final tag = CaptionLayout.measure(
      headline: tagline,
      subtitle: '',
      style: st,
      maxWidth: textW,
      baseSize: h * 0.075 / st.sizeFactor,
      rtl: rtl,
      maxLines: 3,
      align: TextAlign.start,
    );
    final blockH = name.height + h * 0.03 + (plainCaption(tagline).isEmpty ? 0 : tag.height);
    final top = (h - blockH) / 2;
    final textLeft = rtl ? w - textW - w * 0.06 : w * 0.06;

    Widget device(int i, double angle) => Transform.rotate(
      angle: angle,
      child: DeviceFrame(
        shot: scene.shots[i % scene.shots.length],
        device: scene.device,
        frame: scene.frame,
        statusBar: scene.config.statusBar,
        framed: true,
        accent: st.accent,
        drawHighlight: false,
        textDirection: scene.direction,
      ),
    );

    final dw = w * 0.2;
    final probe = DeviceFrame(
      shot: scene.shots.first,
      device: scene.device,
      frame: scene.frame,
      statusBar: scene.config.statusBar,
      framed: true,
    );
    final dh = dw / probe.aspectRatio;
    final dir = rtl ? -1.0 : 1.0;
    final baseX = rtl ? w * 0.08 : w - w * 0.08 - dw * 1.75;

    return Directionality(
      textDirection: scene.direction,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackdropPainter(
                  kind: st.backdrop,
                  colors: st.colors,
                  accent: st.accent,
                  glowAt: Offset(rtl ? 0.25 : 0.75, 0.55),
                ),
              ),
            ),
            Positioned(
              left: baseX + (rtl ? dw * 0.75 : 0),
              top: h * 0.2,
              width: dw,
              height: dh,
              child: device(1, -0.12 * dir),
            ),
            Positioned(
              left: baseX + (rtl ? 0 : dw * 0.75),
              top: h * 0.08,
              width: dw,
              height: dh,
              child: device(0, 0.1 * dir),
            ),
            Positioned(
              left: textLeft,
              top: top,
              width: textW,
              height: blockH + 8,
              child: CustomPaint(painter: _FgTextPainter(name, tag, h * 0.03, rtl, textW)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FgTextPainter extends CustomPainter {
  _FgTextPainter(this.name, this.tag, this.gap, this.rtl, this.width);
  final TextPainter name;
  final CaptionLayout tag;
  final double gap;
  final bool rtl;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    name.paint(canvas, Offset(rtl ? width - name.width : 0, 0));
    tag.paint(canvas, Offset(0, name.height + gap), width, TextAlign.start, rtl);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
