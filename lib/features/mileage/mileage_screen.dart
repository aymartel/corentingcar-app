import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/brand/brand.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/models/models.dart';
import '../usage_history/usage_history_screen.dart';
import 'mileage_controller.dart';

/// Pantalla KILÓMETROS (Fase F6): consumo del año por persona (cupo por persona),
/// km compartidos (50/50) y aviso de exceso. `GET /api/mileage`.
class MileageScreen extends ConsumerWidget {
  const MileageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mileageControllerProvider);
    final controller = ref.read(mileageControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KILÓMETROS'),
        actions: [
          IconButton(
            tooltip: 'Historial de usos',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UsageHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface,
        onRefresh: controller.refresh,
        child: AsyncStateView<MileageSummary>(
          value: async,
          onRetry: controller.refresh,
          errorFallback: 'No se pudieron cargar los kilómetros.',
          data: (summary) => _MileageContent(summary: summary),
        ),
      ),
    );
  }
}

class _MileageContent extends StatelessWidget {
  const _MileageContent({required this.summary});

  final MileageSummary summary;

  @override
  Widget build(BuildContext context) {
    final exceeded = summary.people.where((p) => p.exceeded).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (exceeded.isNotEmpty) ...[
          _ExcessBanner(people: exceeded, limit: summary.annualKmPerPerson),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text('POR PERSONA', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        for (final person in summary.people) ...[
          _PersonMileageCard(
            person: person,
            limit: summary.annualKmPerPerson,
            summary: summary,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('COMPARTIDOS', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        _SharedCard(summary: summary),
        const SizedBox(height: AppSpacing.xl),
        Text('RESUMEN ANUAL', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.md),
        _AnnualCard(summary: summary),
      ],
    );
  }
}

/// Barra de progreso estilo cuadro de mandos (track + relleno con degradado).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.ratio, required this.fill});

  final double ratio;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.rsm,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      height: 14,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: ratio.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [fill.withValues(alpha: 0.6), fill],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonMileageCard extends StatelessWidget {
  const _PersonMileageCard({
    required this.person,
    required this.limit,
    required this.summary,
  });

  final PersonMileage person;
  final int limit;
  final MileageSummary summary;

  @override
  Widget build(BuildContext context) {
    final user = person.user;
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    final ratio = limit == 0 ? 0.0 : person.usedKm / limit;
    final nearLimit = !person.exceeded && ratio >= 0.85;
    final fill = person.exceeded
        ? AppColors.danger
        : nearLimit
        ? AppColors.warning
        : color;
    final theme = Theme.of(context);

    return GlowCard(
      accentColor: color,
      glow: person.exceeded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(
                name: user.name,
                profile: user.profile,
                color: color,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(user.name, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${EsFormat.km(person.usedKm)} / ${EsFormat.km(limit)} km',
                style: AppTypography.mono(
                  size: 15,
                  weight: FontWeight.w700,
                  color: fill,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressBar(ratio: ratio, fill: fill),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Restantes',
                  value: '${EsFormat.km(person.remainingKm)} km',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Individuales',
                  value: '${EsFormat.km(person.individualKm)} km',
                ),
              ),
            ],
          ),
          if (summary.kmStartDate != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _PaceSection(person: person, summary: summary, color: color),
          ],
          if (person.exceeded) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Exceso: ${EsFormat.km(person.excessKm)} km · lo paga quien lo genera',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Ritmo ACUMULADO desde el primer uso: barra con lo aconsejado hasta hoy (gris,
/// el cupo arrastrado) y lo realmente usado (color de la persona). Si el color
/// supera al gris vas por encima (gastas tu colchón); si no, ahorras km.
class _PaceSection extends StatelessWidget {
  const _PaceSection({
    required this.person,
    required this.summary,
    required this.color,
  });

  final PersonMileage person;
  final MileageSummary summary;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = person.usedSinceStart;
    final recommended = summary.recommendedToDate;
    final diff = used - recommended;
    final ahead = diff > 0; // por encima del ritmo aconsejado (consume colchón)
    final statusColor = ahead ? AppColors.warning : AppColors.success;
    final statusText = ahead
        ? '${EsFormat.km(diff)} km por encima'
        : '${EsFormat.km(-diff)} km por debajo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('RITMO ACUMULADO', style: AppTypography.hudLabel()),
            const Spacer(),
            Text(
              statusText,
              style: AppTypography.hudLabel(color: statusColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaceBar(used: used, recommended: recommended, color: color),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Usado ${EsFormat.km(used)} · aconsejado ${EsFormat.km(recommended)} km '
          '(${summary.daysSinceStart} días desde el inicio)',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          'Aconsejado · mes ${EsFormat.km(summary.monthlyKmPerPerson)} · '
          'año ${EsFormat.km(summary.annualKmPerPerson)} km · '
          '${EsFormat.decimal(summary.dailyKmPerPerson)}/día',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Barra de ritmo acumulado: escala = el mayor entre usado y aconsejado; gris =
/// aconsejado hasta hoy (detrás); color del usuario = realmente usado (delante).
/// Si el color supera al gris, vas por encima del ritmo.
class _PaceBar extends StatelessWidget {
  const _PaceBar({
    required this.used,
    required this.recommended,
    required this.color,
  });

  final double used;
  final double recommended;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = used > recommended ? used : recommended;
    final scale = maxVal <= 0 ? 1.0 : maxVal;
    final usedRatio = (used / scale).clamp(0.0, 1.0);
    final recRatio = (recommended / scale).clamp(0.0, 1.0);
    final overPace = used > recommended;
    final fill = overPace ? AppColors.warning : color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.rsm,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      height: 14,
      child: Stack(
        children: [
          // Aconsejado a hoy (gris, detrás).
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: recRatio,
              child: ColoredBox(
                color: AppColors.textMuted.withValues(alpha: 0.45),
              ),
            ),
          ),
          // Realmente usado (color de la persona, delante).
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: usedRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [fill.withValues(alpha: 0.6), fill],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.mono(size: 15)),
      ],
    );
  }
}

class _ExcessBanner extends StatelessWidget {
  const _ExcessBanner({required this.people, required this.limit});

  final List<PersonMileage> people;

  /// Cupo anual por persona (de `rules`); se muestra en el aviso.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: AppRadius.rmd,
        border: Border.all(color: AppColors.danger),
        boxShadow: AppShadows.glow(AppColors.danger, opacity: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'CUPO SUPERADO',
                style: AppTypography.hudLabel(color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final p in people)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${p.user.name} ha superado los ${EsFormat.km(limit)} km: '
                '${EsFormat.km(p.excessKm)} km de exceso (se pagan).',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _SharedCard extends StatelessWidget {
  const _SharedCard({required this.summary});

  final MileageSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'VIAJES JUNTOS',
                style: AppTypography.hudLabel(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Los kilómetros compartidos se reparten al 50/50; no se cargan a una sola persona.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Total compartido',
                  value: '${EsFormat.decimal(summary.sharedKm)} km',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Por persona',
                  value: '${EsFormat.decimal(summary.sharedKmPerPerson)} km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnualCard extends StatelessWidget {
  const _AnnualCard({required this.summary});

  final MileageSummary summary;

  @override
  Widget build(BuildContext context) {
    final totalUsed = summary.people.fold<int>(0, (sum, p) => sum + p.usedKm);
    final total = summary.annualKmTotal;
    final ratio = total == 0 ? 0.0 : totalUsed / total;
    final theme = Theme.of(context);

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TOTAL', style: AppTypography.hudLabel()),
              const Spacer(),
              Text(
                '${EsFormat.km(totalUsed)} / ${EsFormat.km(total)} km',
                style: AppTypography.mono(size: 15, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressBar(ratio: ratio, fill: AppColors.brand),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${EsFormat.km(summary.annualKmPerPerson)} km por persona al año. '
            'El exceso lo paga quien lo genera.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
