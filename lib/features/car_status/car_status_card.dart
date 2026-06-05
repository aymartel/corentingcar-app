import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/brand/brand.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../login/session_controller.dart';
import 'car_status_controller.dart';
import 'release_sheet.dart';

/// Tarjeta de **disponibilidad real** del coche en HOY (Fase F12): "¿está libre
/// ahora?". Es independiente de la prioridad del día. Verde si está libre, color
/// de la persona si lo tiene alguien; con toggle "Tengo el coche" / "Lo dejo
/// libre".
class CarStatusCard extends ConsumerStatefulWidget {
  const CarStatusCard({super.key});

  @override
  ConsumerState<CarStatusCard> createState() => _CarStatusCardState();
}

class _CarStatusCardState extends ConsumerState<CarStatusCard> {
  bool _acting = false;

  Future<void> _take() async {
    setState(() => _acting = true);
    try {
      await ref.read(carStatusProvider.notifier).take();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('No se pudo actualizar el estado del coche.');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _release() async {
    final ok = await openReleaseSheet(context);
    if (ok == true && mounted) _snack('Coche libre.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(carStatusProvider);
    final status = async.asData?.value;

    if (status == null) {
      if (async.hasError) {
        return _StateCard(
          icon: Icons.wifi_off_outlined,
          accent: AppColors.textMuted,
          title: 'Estado del coche no disponible',
          child: TextButton.icon(
            onPressed: () => ref.read(carStatusProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('REINTENTAR'),
          ),
        );
      }
      return const _StateCard(
        icon: Icons.directions_car_outlined,
        accent: AppColors.textMuted,
        title: 'Comprobando el coche…',
        child: GrilleBars(animate: true, height: 18),
      );
    }

    final me = ref.watch(currentUserProvider);
    final isMine = status.isTaken && status.user?.id == me?.id;
    final theme = Theme.of(context);

    final Color accent;
    final IconData icon;
    final String title;
    if (status.isFree) {
      accent = AppColors.brand;
      icon = Icons.check_circle_outline;
      title = 'Coche libre';
    } else {
      final user = status.user;
      accent =
          colorFromHex(user?.color) ?? personColor(user?.profile ?? 'user1');
      icon = Icons.directions_car_filled;
      title = isMine ? 'Lo tienes tú' : 'Lo tiene ${user?.name ?? '—'}';
    }

    return GlowCard(
      accentColor: accent,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESTADO DEL COCHE', style: AppTypography.hudLabel()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(color: accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.isFree && status.parkingUser != null)
            _InfoLine(
              icon: Icons.home_outlined,
              text: 'Aparcado en casa de ${status.parkingUser!.name}',
            ),
          // Parqueo "Otro": la nota es la ubicación.
          if (status.isFree &&
              status.parking == ParkingSpot.other &&
              (status.note?.isNotEmpty ?? false))
            _InfoLine(
              icon: Icons.place_outlined,
              text: 'Aparcado en: ${status.note}',
            ),
          // Nota suelta (no la mostramos como nota cuando ya es la ubicación de "Otro").
          if ((status.note?.isNotEmpty ?? false) &&
              status.parking != ParkingSpot.other)
            _InfoLine(icon: Icons.sticky_note_2_outlined, text: status.note!),
          if (status.since != null)
            _InfoLine(
              icon: Icons.schedule_outlined,
              text:
                  '${status.isFree ? 'Libre desde' : 'Desde'} '
                  '${_sinceText(status.since!)}',
              mono: true,
            ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _acting
                  ? null
                  : (isMine ? _release : _take),
              icon: _acting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
                      ),
                    )
                  : Icon(isMine ? Icons.logout : Icons.directions_car, size: 18),
              label: Text(isMine ? 'Lo dejo libre' : 'Tengo el coche'),
            ),
          ),
        ],
      ),
    );
  }

  /// Hora local; añade la fecha si no es de hoy.
  String _sinceText(DateTime since) {
    final now = DateTime.now();
    final sameDay =
        since.year == now.year &&
        since.month == now.month &&
        since.day == now.day;
    return sameDay
        ? EsFormat.time(since)
        : '${EsFormat.date(since)} · ${EsFormat.time(since)}';
  }
}

/// Línea de información secundaria (icono + texto) bajo el título.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.mono = false});

  final IconData icon;
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = mono
        ? AppTypography.mono(size: 13, color: AppColors.textSecondary)
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// Tarjeta compacta para los estados de carga/error del estado del coche.
class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      accentColor: accent,
      child: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title, style: AppTypography.hudLabel()),
          ),
          child,
        ],
      ),
    );
  }
}
