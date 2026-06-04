import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'common/theme/theme.dart';
import 'features/login/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Datos de locale para fechas/números es-ES (intl).
  await initializeDateFormatting(AppConstants.intlLocale);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  runApp(const ProviderScope(child: CoRetingCarApp()));
}

/// App CoRetingCar (Fase F1–F3).
///
/// **Dark-only** (F0): un único tema oscuro, sin `ThemeMode.system`. Locale
/// fijo **es-ES**; estado con **Riverpod** (`ProviderScope`). El arranque pasa
/// por el [AuthGate] (login ↔ shell según haya sesión).
class CoRetingCarApp extends StatelessWidget {
  const CoRetingCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: AppConstants.locale,
      supportedLocales: const [AppConstants.locale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
