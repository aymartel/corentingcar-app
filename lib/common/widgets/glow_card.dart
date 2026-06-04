import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Tarjeta base del sistema (Fase F0 · §5): superficie `surface`, borde
/// hairline y radio `md`. Variante con **stripe izquierdo** del color de la
/// persona y *glow* opcional.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.accentColor,
    this.glow = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;

  /// Si se indica, pinta un stripe izquierdo de acento (color de persona).
  final Color? accentColor;

  /// Halo del color de acento (estado enfocado/activo).
  final bool glow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rmd,
        border: Border.all(color: AppColors.outline),
        boxShadow: glow && accent != null
            ? AppShadows.glow(accent, opacity: 0.22)
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.rmd,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(padding: padding, child: child),
                if (accent != null)
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: accent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
