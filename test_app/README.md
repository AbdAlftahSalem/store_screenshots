# test_app: Wallet

The end-to-end test bed for store_shots. Where `example/` shows the happy path, this app exists to catch bugs:

- **Provider** + `ChangeNotifier` (the example uses Riverpod)
- **go_router** with `MaterialApp.router` (the initial route comes from the platform's default route)
- **light + dark** (`ThemeMode.system`)
- **5 devices** including iPad 13" and a 10" Android tablet, and a responsive tablet layout
- custom frames (`iphone_air/sky_blue`, `galaxy/titanium_silverblue`) and a custom status bar (87 % battery)
- the app's own Arabic font (Tajawal, from `FontManifest.json`)
- a highlight on a widget that is off-screen on phones (store_shots must warn, not crash)

```bash
flutter pub get
dart run store_screenshots      # 4 screens × 2 locales × 5 devices × 2 themes = 80 images + 2 Feature Graphics
```

Tajawal is licensed under the SIL OFL 1.1 (`assets/fonts/OFL.txt`).
