# Contributing

Thanks for helping! The short version:

```bash
git clone https://github.com/AbdAlftahSalem/store_shots
cd store_shots && flutter pub get
flutter analyze && flutter test          # package unit + render tests
cd example && flutter pub get && dart run store_screenshots --template all   # visual check
cd ../test_app && flutter pub get && dart run store_screenshots              # end-to-end: Provider, go_router, dark, tablets
```

Open `build/store_shots/gallery.html` in each app and look at the images. A change that touches drawing should
be checked in English **and** Arabic.

## Where things live

- `lib/src/core/`: pure Dart (config parsing, devices, paths, captions, PNG writer, gallery). The CLI imports only this.
- `lib/src/render/`: Flutter (capture runner, fonts, frames, backdrops, templates, Feature Graphic).
- `bin/store_shots.dart`: the CLI.
- `tool/docs_images_test.dart`: regenerates the frames image (`doc/images/frames.png`, convert to JPEG for the README).

## Adding a template

1. Add the id to `kTemplates` and a line to `kTemplateDescriptions` (`lib/src/core/catalog.dart`).
2. Add a `TemplateStyle` to `kTemplateStyles` (`lib/src/render/templates.dart`); reuse a layout or add one to `ShotComposer`.
3. Run the example with `--template your_template` in `en` and `ar`, and add it to the README table.

## Adding a device or frame

Devices and frame models are plain data in `devices.dart` and `catalog.dart`. Always cite the store page for a new size
in the README and in `test/devices_test.dart`. Frames must be generic drawings: no logos or brand artwork.

## Commits and PRs

Small, focused commits with a clear message (`templates: add sunset`, `config: suggest close device ids`).
`flutter analyze` must be clean and `flutter test` green.
