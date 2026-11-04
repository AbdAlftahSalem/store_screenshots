import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'src/model.dart';
import 'src/screens.dart';

void main() => runApp(WalletApp(api: EmptyWalletApi()));

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/activity', builder: (_, _) => const ActivityScreen()),
    GoRoute(path: '/cards', builder: (_, _) => const CardsScreen()),
    GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
  ],
);

class WalletApp extends StatefulWidget {
  const WalletApp({super.key, required this.api});

  final WalletApi api;

  @override
  State<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  // go_router reads the initial location from the platform's default route,
  // which is how store_shots opens each screen.
  late final router = buildRouter();

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F9D7A),
        brightness: b,
      ).copyWith(surface: dark ? const Color(0xFF12161C) : Colors.white),
      scaffoldBackgroundColor: dark ? const Color(0xFF0A0D12) : const Color(0xFFF4F6F8),
      fontFamily: 'Tajawal',
    );
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => WalletModel(widget.api),
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  );
}
