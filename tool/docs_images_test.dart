// Renders doc/images/frames.png (every frame model and color); the README uses a JPEG copy.
// Run: flutter test tool/docs_images_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_shots/src/core/catalog.dart';
import 'package:store_shots/src/core/config.dart';
import 'package:store_shots/src/core/devices.dart';
import 'package:store_shots/src/core/png.dart';
import 'package:store_shots/src/render/device_frame.dart';
import 'package:store_shots/src/render/fonts.dart';

Future<ui.Image> _wallpaper(double w, double h, List<Color> colors, double scale) async {
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  final rect = Rect.fromLTWH(0, 0, w * scale, h * scale);
  c.drawRect(rect, Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, colors));
  final tp = TextPainter(
    text: TextSpan(
      text: '9:41',
      style: TextStyle(fontFamily: 'StoreShotsDisplay', fontSize: w * 0.24 * scale, fontWeight: FontWeight.w600,
          color: const Color(0xEEFFFFFF)),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, Offset((w * scale - tp.width) / 2, h * 0.14 * scale));
  return r.endRecording().toImage((w * scale).round(), (h * scale).round());
}

void main() {
  setUpAll(loadStoreShotsFonts);

  testWidgets('frames showcase', (tester) async {
    const palettes = [
      [Color(0xFF6D5DF6), Color(0xFFEC4899)],
      [Color(0xFF0EA5E9), Color(0xFF22C55E)],
      [Color(0xFFF97316), Color(0xFFDB2777)],
      [Color(0xFF1E293B), Color(0xFF6366F1)],
    ];
    final cards = <Widget>[];
    final models = kFrameModels.values.where((m) => m.shape != FrameShape.tablet).toList();
    for (final m in models) {
      final phone = m.shape == FrameShape.island ? kDevices['iphone_6_9']! : kDevices['android_phone']!;
      for (var i = 0; i < m.finishes.length && i < 4; i++) {
        final img = (await tester.runAsync(() => _wallpaper(phone.screenWidth, phone.screenHeight, palettes[i], 1)))!;
        cards.add(SizedBox(
          width: 148,
          child: Column(children: [
            SizedBox(
              height: 290,
              child: DeviceFrame(
                shot: ScreenShot(image: img, logicalWidth: phone.screenWidth, logicalHeight: phone.screenHeight,
                    darkTop: true, darkBottom: true),
                device: phone,
                frame: FrameChoice(m, m.finishes[i]),
                statusBar: const StatusBarConfig(),
                framed: true,
                shadow: false,
              ),
            ),
            const SizedBox(height: 8),
            Text('${m.id}\n${m.finishes[i].name}', textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'StoreShotsSans', fontSize: 12, color: Color(0xFF333333), height: 1.3)),
          ]),
        ));
      }
    }
    const size = Size(1560, 1170);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFFF4F4F7),
          padding: const EdgeInsets.all(24),
          child: Wrap(spacing: 22, runSpacing: 18, children: cards),
        ),
      ),
    ));
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (image.width, image.height, data!);
    }))!;
    File('doc/images/frames.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeRgbPng(bytes.$3.buffer.asUint8List(), bytes.$1, bytes.$2));
  });
}
