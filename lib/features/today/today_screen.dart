import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/brand/brand.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/models/models.dart';
import '../car_status/car_status_card.dart';
import '../car_status/car_status_controller.dart';
import '../expenses/forms/forms.dart';
import '../requests/request_badge.dart';
import '../requests/request_form.dart';
import '../rules/rules_screen.dart';
import 'today_controller.dart';

/// Pantalla HOY (Fase F4): la más importante. Responde "¿quién tiene prioridad
/// hoy?" con una tarjeta héroe estilo HUD, la frase de conflicto y 4 botones.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOY'),
        actions: [
          const RequestsBadgeButton(),
          IconButton(
            tooltip: 'Reglas y ajustes',
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RulesScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface,
        onRefresh: () => Future.wait([
          controller.refresh(),
          ref.read(carStatusProvider.notifier).refresh(),
        ]),
        child: AsyncStateView<DailyPriority>(
          value: async,
          onRetry: controller.refresh,
          errorFallback: 'No se pudo cargar la prioridad de hoy.',
          data: (priority) => _TodayContent(
            priority: priority,
            onPedir: () => _pedirCoche(context),
          ),
        ),
      ),
    );
  }

  Future<void> _pedirCoche(BuildContext context) async {
    final ok = await openRequestForm(context);
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Solicitud enviada.')));
    }
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.priority, required this.onPedir});

  final DailyPriority priority;
  final VoidCallback onPedir;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Disponibilidad real del coche (F12), lo más visible y accionable.
        const CarStatusCard(),
        const SizedBox(height: AppSpacing.xl),
        Text(_dateLabel(priority.date), style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        _PriorityHero(priority: priority),
        const SizedBox(height: AppSpacing.xl),
        Text('ACCIONES', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        _ActionGrid(onPedir: onPedir),
      ],
    );
  }

  String _dateLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    return date == null ? isoDate : EsFormat.weekday(date).toUpperCase();
  }
}

class _PriorityHero extends StatelessWidget {
  const _PriorityHero({required this.priority});

  final DailyPriority priority;

  @override
  Widget build(BuildContext context) {
    final user = priority.priorityUser;
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    final theme = Theme.of(context);

    final phrase =
        priority.conflictPhrase ??
        'En caso de conflicto hoy decide ${user.name}. '
            'Si no es tu día y necesitas el coche, pídelo.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rlg,
        border: Border.all(color: AppColors.outline),
        boxShadow: AppShadows.glow(color, opacity: 0.16, blur: 28),
      ),
      child: HudFrame(
        color: color,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PersonAvatar(
                  name: user.name,
                  profile: user.profile,
                  color: color,
                  size: 64,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOY TIENE PRIORIDAD',
                        style: AppTypography.hudLabel(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user.name,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: color,
                        ),
                      ),
                      if (priority.isMyDay) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _MyDayChip(color: color),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // El coche junto al texto de prioridad.
                Image.asset(
                  'assets/brand/car_logo.png',
                  height: 62,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text(phrase, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MyDayChip extends StatelessWidget {
  const _MyDayChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: color),
      ),
      child: Text('ES TU DÍA', style: AppTypography.hudLabel(color: color)),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.onPedir});

  final VoidCallback onPedir;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.3,
      children: [
        _ActionTile(
          icon: Icons.front_hand_outlined,
          label: 'Pedir coche',
          // Siempre disponible: el día se elige en el formulario (el backend
          // rechaza pedir tu propio día).
          onTap: onPedir,
        ),
        _ActionTile(
          icon: Icons.speed_outlined,
          label: 'Registrar uso',
          onTap: () => _handle(context, openUsageForm, 'Uso registrado.'),
        ),
        _ActionTile(
          icon: Icons.local_gas_station_outlined,
          label: 'Gasolina',
          onTap: () => _handle(context, openFuelForm, 'Gasolina registrada.'),
        ),
        _ActionTile(
          icon: Icons.local_car_wash_outlined,
          label: 'Lavado',
          onTap: () => _handle(context, openWashForm, 'Lavado registrado.'),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    Future<bool?> Function(BuildContext) opener,
    String successMessage,
  ) async {
    final ok = await opener(context);
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brand, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.hudLabel(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // "+" a la derecha: deja claro que la tarjeta es un botón de acción.
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.outlineStrong),
            ),
            child: const Icon(Icons.add, size: 15, color: AppColors.brand),
          ),
        ],
      ),
    );
  }
}
