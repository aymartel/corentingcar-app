import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// **Contornos topográficos** (Fase F0 · §4): textura muy sutil de líneas de
/// contorno (mapa off-road) sobre el fondo negro. Pensada para login,
/// cabeceras y estados vacíos. Nunca debe restar legibilidad.
class BrandBackground extends StatelessWidget {
  const BrandBackground({
    super.key,
    required this.child,
    this.color = AppColors.brand,
    this.opacity = 0.05,
    this.lineCount = 7,
  });

  final Widget child;
  final Color color;

  /// Opacidad de las líneas (4–6% recomendado).
  final double opacity;
  final int lineCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: CustomPaint(
        painter: _ContourPainter(
          color: color.withValues(alpha: opacity),
          lineCount: lineCount,
        ),
        child: child,
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter({required this.color, required this.lineCount});

  final Color color;
  final int lineCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final spacing = size.height / (lineCount + 1);
    for (var i = 1; i <= lineCount; i++) {
      final baseY = spacing * i;
      final path = Path();
      final amplitude = 18.0 + (i % 3) * 10.0;
      final wavelength = size.width / (1.4 + (i % 4) * 0.35);
      final phase = i * 0.7;
      for (double x = 0; x <= size.width; x += 8) {
        final y =
            baseY +
            amplitude * math.sin((x / wavelength) * 2 * math.pi + phase);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourPainter old) =>
      old.color != color || old.lineCount != lineCount;
}
