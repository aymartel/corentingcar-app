import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_exception.dart';
import '../theme/theme.dart';
import 'brand/brand.dart';

/// Vistas de estado reutilizables (carga/vacío/error) de marca dark/JEEP.
///
/// Introducidas en F4 y **unificadas en F10**: todas las pantallas
/// (`AsyncStateView`) usan los mismos widgets de carga/error/vacío.

/// Indicador de carga: la parrilla de 7 ranuras animada.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GrilleBars(animate: true, height: 32, barWidth: 5),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: AppTypography.hudLabel()),
          ],
        ],
      ),
    );
  }
}

/// Estado de error con mensaje en español y botón de reintento.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppColors.textMuted,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('REINTENTAR'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Envuelve un contenido centrado para que siga permitiendo el gesto de
/// `pull-to-refresh` (ocupa al menos el alto del viewport y es desplazable).
class RefreshableCenter extends StatelessWidget {
  const RefreshableCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Estado **vacío** (sin datos que mostrar, sin error). Mensaje en español.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renderiza un [AsyncValue] de forma **uniforme** en toda la app (F10):
/// datos (incluso refrescando) → [data]; error → [ErrorView] con reintento;
/// si no, [LoadingView]. Los estados de carga/error van envueltos en
/// [RefreshableCenter] para conservar el gesto de pull-to-refresh.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.errorFallback = 'No se pudo cargar la información.',
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? onRetry;
  final String errorFallback;

  @override
  Widget build(BuildContext context) {
    final current = value.asData?.value;
    if (current != null) return data(current);

    if (value.hasError) {
      final error = value.error;
      return RefreshableCenter(
        child: ErrorView(
          message: error is ApiException ? error.message : errorFallback,
          onRetry: onRetry,
        ),
      );
    }
    return const RefreshableCenter(child: LoadingView(message: 'CARGANDO'));
  }
}
