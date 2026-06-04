import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// La **parrilla de 7 ranuras** de JEEP (Fase F0 · §4): el motivo de marca más
/// reconocible. Una fila de barras verticales redondeadas.
///
/// Úsala como sello/logo (login, splash), indicador activo de navegación,
/// divisor de secciones o —con [animate]— como indicador de carga (las barras
/// laten en secuencia).
class GrilleBars extends StatefulWidget {
  const GrilleBars({
    super.key,
    this.color = AppColors.brand,
    this.barCount = 7,
    this.height = 28,
    this.barWidth = 5,
    this.gap = 4,
    this.glow = true,
    this.animate = false,
  });

  final Color color;
  final int barCount;
  final double height;
  final double barWidth;
  final double gap;

  /// Halo de glow del color de marca alrededor de las barras.
  final bool glow;

  /// Si es `true`, las barras laten en secuencia (indicador de carga).
  final bool animate;

  @override
  State<GrilleBars> createState() => _GrilleBarsState();
}

class _GrilleBarsState extends State<GrilleBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Inicializar siempre (aunque no se anime) para que el ticker se cree con
    // un contexto válido y dispose() sea seguro.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant GrilleBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _row((_) => 1);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _row((i) {
          // Onda que recorre las barras de izquierda a derecha.
          final phase =
              (_controller.value * 2 * math.pi) -
              (i / widget.barCount) * 2 * math.pi;
          return 0.4 + 0.6 * (0.5 + 0.5 * math.sin(phase));
        });
      },
    );
  }

  Widget _row(double Function(int index) intensityOf) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          final t = intensityOf(i);
          final bar = Container(
            width: widget.barWidth,
            height: widget.height * (widget.animate ? (0.55 + 0.45 * t) : 1),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: widget.animate ? t : 1),
              borderRadius: BorderRadius.circular(widget.barWidth),
              boxShadow: widget.glow
                  ? AppShadows.glow(widget.color, opacity: 0.25 * t, blur: 12)
                  : null,
            ),
          );
          return Padding(
            padding: EdgeInsets.only(
              right: i == widget.barCount - 1 ? 0 : widget.gap,
            ),
            child: bar,
          );
        }),
      ),
    );
  }
}
