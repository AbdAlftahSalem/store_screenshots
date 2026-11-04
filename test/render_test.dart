import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_shots/src/core/catalog.dart';
import 'package:store_shots/src/core/config.dart';
import 'package:store_shots/src/core/devices.dart';
import 'package:store_shots/src/render/device_frame.dart';
import 'package:store_shots/src/render/fonts.dart';
import 'package:store_shots/src/render/templates.dart';

Future<ui.Image> _solid(int w, int h) async {
  final r = ui.PictureRecorder();
  Canvas(r).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = const Color(0xFFFFFFFF));
  return r.endRecording().toImage(w, h);
}

void main() {
  setUpAll(loadStoreShotsFonts);

  testWidgets('every template and frame paints without errors', (tester) async {
    final image = (await tester.runAsync(() => _solid(44, 96)))!;
    final shot = ScreenShot(
      image: image,
      logicalWidth: 440,
      logicalHeight: 956,
      darkTop: false,
      darkBottom: false,
      highlight: const Rect.fromLTWH(40, 800, 360, 56),
      highlightConfig: const HighlightConfig(key: 'k', style: HighlightStyle.arrow),
      highlightLabel: 'Tap here',
    );
    final cfg = StoreShotsConfig.parse('screens: [a, b]', projectDir: '/x');
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(660, 1434);
    addTearDown(tester.view.reset);
    for (final t in kTemplates) {
      for (final rtl in [false, true]) {
        final model = kFrameModels.values.elementAt(kTemplates.indexOf(t) % 6);
        await tester.pumpWidget(ShotComposer(
          size: const Size(660, 1434),
          scene: ShotScene(
            style: kTemplateStyles[t]!,
            device: kDevices['iphone_6_9']!,
            frame: FrameChoice(model, model.finishes.last),
            config: cfg,
            shots: [shot, shot],
            index: 0,
            headline: rtl ? 'كل شي *بمكان واحد*' : 'Everything *in one place*',
            subtitle: 'Subtitle',
            rtl: rtl,
          ),
        ));
        expect(tester.takeException(), isNull, reason: '$t rtl=$rtl');
      }
    }
  });

  test('every config template has a style', () {
    for (final t in kTemplates) {
      expect(kTemplateStyles[t], isNotNull, reason: t);
      expect(kTemplateDescriptions[t], isNotNull, reason: t);
    }
  });
}
