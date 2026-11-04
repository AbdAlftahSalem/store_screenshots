/// Generate App Store and Google Play screenshots from your Flutter app
/// inside `flutter test`: device frames, translated captions, RTL, ten
/// templates, highlights and the Play Feature Graphic.
library;

export 'src/core/captions.dart' show parseCaption, plainCaption, CaptionSpan, Captions;
export 'src/core/catalog.dart' show kFrameModels, kTemplates, kTemplateDescriptions, FrameModel, FrameFinish;
export 'src/core/config.dart'
    show StoreShotsConfig, ScreenConfig, HighlightConfig, HighlightStyle, ConfigException, StatusBarConfig;
export 'src/core/devices.dart' show DeviceSpec, Store, kDevices;
export 'src/render/device_frame.dart' show DeviceFrame, ScreenShot;
export 'src/render/fonts.dart' show loadStoreShotsFonts;
export 'src/render/runner.dart'
    show storeShots, ShotContext, StoreShots, AppBuilder, OverridesBuilder, BeforeShot, toLocale;
