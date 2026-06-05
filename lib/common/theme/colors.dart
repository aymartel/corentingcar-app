import 'package:flutter/widgets.dart';

/// Design tokens for the CoRetingCar app (Fase F0 · sistema de diseño).
///
/// Dark-only, JEEP-inspired palette. Screens must NEVER hardcode colors:
/// always reference a token from here (or [personColor]).
abstract final class AppColors {
  AppColors._();

  // --- Negros y superficies (base) ---
  /// Obsidiana — fondo de la app (`scaffoldBackgroundColor`).
  static const Color bg = Color(0xFF0A0B09);

  /// Carbón — tarjetas, sheets.
  static const Color surface = Color(0xFF121410);

  /// Grafito — superficie elevada, inputs, items de lista.
  static const Color surfaceAlt = Color(0xFF1A1D16);

  /// Modal — modales/diálogos, menús.
  static const Color surfaceHigh = Color(0xFF222519);

  /// Hairline — bordes finos 1px, divisores.
  static const Color outline = Color(0xFF2E332A);

  /// Bordes activos/hover, marcos HUD.
  static const Color outlineStrong = Color(0xFF444B3A);

  // --- Acentos de marca ---
  /// Verde Patrulla JEEP — acento principal, CTAs, foco, estado activo, Andy.
  static const Color brand = Color(0xFF9CC93B);

  /// Oliva — verde apagado: bordes sutiles, fondos de chip, tracks.
  static const Color brandDeep = Color(0xFF5C6B2E);

  /// Ámbar Trail — acento secundario, badges, Dennis.
  static const Color accentAmber = Color(0xFFFF8A3D);

  // --- Texto ---
  /// Niebla — texto principal (blanco roto, no blanco puro).
  static const Color textPrimary = Color(0xFFECEFE3);

  /// Salvia — texto secundario, subtítulos, labels.
  static const Color textSecondary = Color(0xFF9BA288);

  /// Deshabilitado, placeholders, ayudas.
  static const Color textMuted = Color(0xFF5E6552);

  /// Texto/icono sobre verde o ámbar (casi negro, alto contraste).
  static const Color onAccent = Color(0xFF0A0B09);

  // --- Semánticos ---
  /// Éxito, confirmaciones.
  static const Color success = Color(0xFF7BD15A);

  /// Avisos, "cerca del límite" de km.
  static const Color warning = Color(0xFFFFB02E);

  /// Rojo Señal — errores, aviso de exceso de km, acciones destructivas.
  static const Color danger = Color(0xFFFF5247);

  /// Acero — informativo neutro.
  static const Color info = Color(0xFF7FA8C9);

  // --- Colores por persona (canónicos) ---
  /// Andy — verde JEEP (= [brand]).
  static const Color user1 = brand;

  /// Dennis — ámbar (= [accentAmber]).
  static const Color user2 = accentAmber;
}

/// Color de marca de una persona a partir de su `profile` (`'user1'`/`'user2'`).
///
/// Si el backend envía `users.color`, la UI lo respeta; este helper es el
/// fallback canónico (y la fuente de verdad de los hex sembrados en B2).
Color personColor(String profile) {
  switch (profile.toLowerCase()) {
    case 'user2':
      return AppColors.user2;
    case 'user1':
    default:
      return AppColors.user1;
  }
}

/// Convierte un color hex (`#RRGGBB` o `#AARRGGBB`) en [Color]. Devuelve null
/// si la cadena es nula o no válida (la UI cae entonces a [personColor]).
Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  var value = hex.trim().replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}
