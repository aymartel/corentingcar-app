import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'brand/brand.dart';

/// Placeholder de marca para pantallas aún no implementadas (Fase F1).
///
/// Mantiene la estética dark/JEEP (fondo negro, parrilla de 7 ranuras) mientras
/// la fase correspondiente añade el contenido real.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.phase,
  });

  final String title;
  final IconData icon;

  /// Fase que implementará esta pantalla (p.ej. `'F4'`).
  final String phase;

  @override
  Widget build(BuildContext context) {
    return BrandBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GrilleBars(height: 36, barWidth: 6),
            const SizedBox(height: AppSpacing.xl),
            Icon(icon, size: 44, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Disponible en la fase $phase',
              style: AppTypography.hudLabel(),
            ),
          ],
        ),
      ),
    );
  }
}
