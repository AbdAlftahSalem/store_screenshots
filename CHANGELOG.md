# Changelog

## 0.1.0

First release.

- `storeShots()` test API: renders every screen × locale × device × theme inside `flutter test`, no emulator.
- `store_shots.yaml` with defaults for everything but `screens`, validated with "did you mean…?" errors.
- Devices with verified store sizes (Nov 2026): iPhone 6.9" / 6.5" / 6.3", iPad 13", Android phone, 7" and 10" tablets.
- Real fonts in tests: the app's own fonts, Material Icons and a bundled Roboto + Noto Arabic stand-in for system fonts.
- Captions from `store_<locale>.arb` with `*emphasis*`, line breaks, subtitles and auto-fit; full RTL support.
- 10 templates: aurora, clean, midnight, tilted, duo, panorama, bold, glass, spotlight, pastel (+ `none` for raw shots).
- Device frames drawn in Dart: iPhone 17 / 17 Pro / Air styles, Pixel / Galaxy / classic Android styles, iPad and Android tablet, with colors.
- Mocked status bar (9:41, battery, signal, Wi-Fi) with automatic icon contrast, home indicator / gesture bar.
- Highlights (`ring`, `arrow`, `spotlight`) on any widget by `ValueKey`, with translated labels.
- Google Play Feature Graphic (1024×500) per locale.
- Light and dark runs; template and color overrides.
- Opaque 24-bit PNGs in fastlane `deliver` / `supply` folders, `gallery.html` and `manifest.json`.
- CLI: `dart run store_shots` (run, `init`, `templates`, `devices`, `frames`, filters, `--open`).
