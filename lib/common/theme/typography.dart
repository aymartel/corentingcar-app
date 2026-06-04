import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Tipografía de marca (Fase F0 · §2).
///
/// - **Rajdhani** → display, títulos y labels (técnica, automoción; en
///   MAYÚSCULAS con letter-spacing para efecto HUD).
/// - **Inter** → cuerpo y copy en español.
/// - **JetBrains Mono** (cifras tabulares) → números: km, €, contadores, PIN.
abstract final class AppTypography {
  AppTypography._();

  /// Cifras tabulares para alinear números como un odómetro.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// `TextTheme` completo del tema oscuro: Inter como base de cuerpo y
  /// Rajdhani en display/títulos/labels.
  static TextTheme textTheme() {
    final body = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    TextStyle rajdhani({
      required double size,
      FontWeight weight = FontWeight.w600,
      double spacing = 0.5,
      Color color = AppColors.textPrimary,
    }) => GoogleFonts.rajdhani(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.1,
      color: color,
    );

    return body.copyWith(
      displayLarge: rajdhani(size: 32, weight: FontWeight.w700),
      displayMedium: rajdhani(size: 28, weight: FontWeight.w700),
      displaySmall: rajdhani(size: 24, weight: FontWeight.w700),
      headlineMedium: rajdhani(size: 22, weight: FontWeight.w700),
      titleLarge: rajdhani(size: 22, weight: FontWeight.w600),
      titleMedium: rajdhani(size: 18, weight: FontWeight.w600),
      titleSmall: rajdhani(size: 15, weight: FontWeight.w600, spacing: 0.8),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
      // Labels en Rajdhani, pensados para usarse en MAYÚSCULAS con tracking.
      labelLarge: rajdhani(size: 14, weight: FontWeight.w600, spacing: 1.4),
      labelMedium: rajdhani(
        size: 12,
        weight: FontWeight.w600,
        spacing: 1.6,
        color: AppColors.textSecondary,
      ),
      labelSmall: rajdhani(
        size: 11,
        weight: FontWeight.w600,
        spacing: 1.8,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Label de sección estilo HUD (Rajdhani, mayúsculas + tracking).
  static TextStyle hudLabel({Color color = AppColors.textSecondary}) =>
      GoogleFonts.rajdhani(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: color,
      );

  /// Número de odómetro (JetBrains Mono, tabular). Para km/€/contadores/PIN.
  static TextStyle odometer({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: _tabular,
    letterSpacing: 0.5,
  );

  /// Texto numérico mono en línea (importes, fechas numéricas).
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: _tabular,
  );
}
