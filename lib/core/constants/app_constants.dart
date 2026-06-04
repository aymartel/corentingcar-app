import 'package:flutter/widgets.dart';

/// Constantes transversales de la app (Fase F1). Identificadores en inglés.
abstract final class AppConstants {
  AppConstants._();

  /// Nombre visible de la app.
  static const String appName = 'CoRetingCar';

  /// Versión visible de la app (coincide con `pubspec.yaml`; F11 la formaliza).
  static const String appVersion = '1.0.0';

  /// Prefijo del contrato de la API (ver `00-context-and-contract.md`).
  static const String apiPrefix = '/api';

  /// Locale único de la UI: español de España (ver F0/F1).
  static const Locale locale = Locale('es', 'ES');

  /// Etiqueta de `intl` para fechas/números es-ES.
  static const String intlLocale = 'es_ES';
}
