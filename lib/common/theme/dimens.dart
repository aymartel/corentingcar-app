import 'package:flutter/widgets.dart';

/// Radios de marca (Fase F0 · §3). Geométrico/táctico, nada tipo burbuja.
abstract final class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius rsm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rmd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rlg = BorderRadius.all(Radius.circular(lg));
}

/// Escala de espaciado base 4.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Elevación = borde + *glow* (Fase F0 · §3): no usamos sombras grises de
/// Material claro, sino un halo del color de acento a baja opacidad.
abstract final class AppShadows {
  AppShadows._();

  static List<BoxShadow> glow(
    Color color, {
    double opacity = 0.18,
    double blur = 22,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: -2,
    ),
  ];
}
