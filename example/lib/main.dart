import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/screens.dart';

void main() => runApp(const ProviderScope(child: ShopApp()));

const _seed = Color(0xFF5B4CF0);

/// Basket: a small shop used to show what store_shots produces.
class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  ThemeData _theme(Brightness brightness, Locale? locale) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme.copyWith(
        primary: dark ? const Color(0xFF8F84FF) : _seed,
        surface: dark ? const Color(0xFF111118) : Colors.white,
      ),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0B0B10)
          : const Color(0xFFF7F7FB),
      // Arabic gets a real Arabic font; Latin keeps the platform font.
      fontFamily: locale?.languageCode == 'ar' ? 'IBMPlexSansArabic' : null,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Basket',
    debugShowCheckedModeBanner: false,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) {
      final locale = Localizations.localeOf(context);
      final brightness = MediaQuery.platformBrightnessOf(context);
      return Theme(data: _theme(brightness, locale), child: child!);
    },
    theme: _theme(Brightness.light, null),
    onGenerateRoute: (settings) {
      final uri = Uri.parse(settings.name ?? '/');
      final page = switch (uri.pathSegments) {
        [] => const HomeScreen(),
        ['product', final id] => ProductScreen(id: id),
        ['cart'] => const CartScreen(),
        ['orders'] => const TrackOrderScreen(),
        _ => null,
      };
      return page == null
          ? null
          : MaterialPageRoute<void>(settings: settings, builder: (_) => page);
    },
  );
}
