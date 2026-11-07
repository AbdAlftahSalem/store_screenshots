# store_shots example: Basket

A small shop app (Riverpod, English + Arabic) that generates its own App Store and Google Play screenshots.

```bash
flutter pub get
dart run store_screenshots                  # 4 screens × en/ar × iPhone 6.9" + Android phone
dart run store_screenshots --template all   # every template, into build/store_shots/variants/
```

- `store_shots.yaml`: screens, devices, highlights.
- `lib/l10n/store_en.arb`, `store_ar.arb`: the captions.
- `test/store_shots_test.dart`: the fake, locale-aware data (Riverpod overrides).

The app has no backend on purpose: run it normally and the screens are empty. The fakes are what make the
screenshots look real, which is the whole point.

Product photos in `assets/products/` were generated for this example; fonts in `assets/fonts/` are
IBM Plex Sans Arabic (SIL OFL 1.1, see `assets/fonts/OFL.txt`). To run it on a device, add platforms with
`flutter create .`.
