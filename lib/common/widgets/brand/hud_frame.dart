import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// **Marco de visor / HUD** (Fase F0 · §4): dibuja corchetes finos en las
/// cuatro esquinas alrededor de un dato clave (p.ej. la prioridad del día).
class HudFrame extends StatelessWidget {
  const HudFrame({
    super.key,
    required this.child,
    this.color = AppColors.brand,
    this.cornerLength = 18,
    this.strokeWidth = 2,
    this.gap = 6,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.glow = true,
  });

  final Widget child;
  final Color color;

  /// Longitud de cada brazo del corchete.
  final double cornerLength;
  final double strokeWidth;

  /// Separación entre el corchete y el contenido.
  final double gap;
  final EdgeInsetsGeometry padding;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HudCornersPainter(
        color: color,
        cornerLength: cornerLength,
        strokeWidth: strokeWidth,
        glow: glow,
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _HudCornersPainter extends CustomPainter {
  _HudCornersPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.glow,
  });

  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (glow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    }

    final l = cornerLength;
    final w = size.width;
    final h = size.height;

    // Esquina superior izquierda.
    _corner(canvas, paint, const Offset(0, 0), Offset(l, 0), Offset(0, l));
    // Superior derecha.
    _corner(canvas, paint, Offset(w, 0), Offset(w - l, 0), Offset(w, l));
    // Inferior izquierda.
    _corner(canvas, paint, Offset(0, h), Offset(l, h), Offset(0, h - l));
    // Inferior derecha.
    _corner(canvas, paint, Offset(w, h), Offset(w - l, h), Offset(w, h - l));
  }

  void _corner(Canvas canvas, Paint paint, Offset corner, Offset a, Offset b) {
    canvas.drawLine(corner, a, paint);
    canvas.drawLine(corner, b, paint);
  }

  @override
  bool shouldRepaint(covariant _HudCornersPainter old) =>
      old.color != color ||
      old.cornerLength != cornerLength ||
      old.strokeWidth != strokeWidth ||
      old.glow != glow;
}
