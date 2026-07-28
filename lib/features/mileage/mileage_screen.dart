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

// Cuánto puedes pasarte del cupo antes de que la barra se ponga roja.
const double _annualToleranceKm = 500;

/// Margen del mes, proporcional al cupo para que no dependa del plan contratado
/// (con 625 km/mes son 50 km, con 1.042 son ~52).
double _monthlyTolerance(double budget) =>
    budget <= 0 ? 50 : (budget * 0.08).clamp(50, 200);

/// Color de la barra según el consumo frente al **cupo del periodo**:
/// verde mientras no lo superes —ir por debajo NUNCA es un aviso—, naranja al
/// superarlo y rojo cuando te pasas del margen.
Color budgetColor(double used, double budget, double tolerance) {
  if (budget <= 0) return AppColors.success;
  if (used > budget + tolerance) return AppColors.danger;
  if (used > budget) return AppColors.warning;
  return AppColors.success;
}

/// Texto informativo del ritmo (`d = usado − aconsejado`). Se pinta en color
/// neutro: informa de si vas adelantado o retrasado, pero no alarma.
String _deviationText(double d) {
  if (d.abs() < 0.5) return 'en línea';
  return d > 0
      ? '${EsFormat.km(d)} km por encima'
      : '${EsFormat.km(-d)} km por debajo';
}

/// Barra de desviación: sobre el track, el GRIS marca lo aconsejado (altura
/// completa, por donde debes ir) y encima una banda más fina con lo USADO
/// (verde/naranja/rojo según desviación). Ambas se ven aunque se solapen.
class _DeviationBar extends StatelessWidget {
  const _DeviationBar({
    required this.used,
    required this.recommended,
    required this.scale,
    required this.tolerance,
  });

  final double used;
  final double recommended;
  final double scale;
  final double tolerance;

  @override
  Widget build(BuildContext context) {
    final s = scale <= 0 ? 1.0 : scale;
    final usedRatio = (used / s).clamp(0.0, 1.0);
    final recRatio = (recommended / s).clamp(0.0, 1.0);
    // El color lo manda el CUPO del periodo (`scale`), no el ritmo: ir por debajo
    // del aconsejado no es un problema y debe seguir en verde.
    final fill = budgetColor(used, scale, tolerance);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.rsm,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      height: 16,
      child: Stack(
        children: [
          // Aconsejado (gris), altura completa, detrás.
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: recRatio,
              child: ColoredBox(
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Usado (color por desviación), banda más fina centrada, delante.
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: usedRatio,
              heightFactor: 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.rsm,
                  gradient: LinearGradient(
                    colors: [fill.withValues(alpha: 0.7), fill],
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

/// Barra de progreso simple (track + relleno). Para el resumen total del año.
class _SimpleBar extends StatelessWidget {
  const _SimpleBar({required this.ratio, required this.fill});

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

/// Bloque etiquetado: cabecera (título + desviación en color), la barra y el pie
/// con las cifras (usado vs aconsejado). Reutilizado por la barra anual y la mensual.
class _DeviationBlock extends StatelessWidget {
  const _DeviationBlock({
    required this.label,
    required this.used,
    required this.recommended,
    required this.scale,
    required this.tolerance,
  });

  final String label;
  final double used;
  final double recommended;
  final double scale;
  final double tolerance;

  @override
  Widget build(BuildContext context) {
    final d = used - recommended;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.hudLabel(),
              ),
            ),
            // El ritmo se informa en color neutro; el aviso lo da la barra (cupo).
            Text(_deviationText(d), style: AppTypography.hudLabel()),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DeviationBar(
          used: used,
          recommended: recommended,
          scale: scale,
          tolerance: tolerance,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Usado ${EsFormat.km(used)} · aconsejado ${EsFormat.km(recommended)} km',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
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
    final theme = Theme.of(context);
    final headerColor = budgetColor(
      person.usedKm.toDouble(),
      limit.toDouble(),
      _annualToleranceKm,
    );

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
                  color: headerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Barra del AÑO (se reinicia el 1 de enero): usado vs aconsejado del año.
          _DeviationBlock(
            label: 'CUPO ${summary.windowYear}',
            used: person.usedKm.toDouble(),
            recommended: summary.recommendedYearToDate,
            scale: limit.toDouble(),
            tolerance: _annualToleranceKm,
          ),
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
          // Barra MENSUAL (se reinicia el día 1): carrusel por meses registrados.
          if (summary.months.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _MonthlyCarousel(
              months: summary.months,
              userId: user.id,
              monthlyBudget: summary.monthlyKmPerPerson,
            ),
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

/// Carrusel MENSUAL: una barra por mes registrado (se reinicia el día 1). Swipe
/// horizontal para ver todos los meses; por defecto muestra el mes en curso.
class _MonthlyCarousel extends StatefulWidget {
  const _MonthlyCarousel({
    required this.months,
    required this.userId,
    required this.monthlyBudget,
  });

  final List<MonthMileage> months;
  final int userId;
  final int monthlyBudget;

  @override
  State<_MonthlyCarousel> createState() => _MonthlyCarouselState();
}

class _MonthlyCarouselState extends State<_MonthlyCarousel> {
  late PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.months.length - 1; // por defecto el mes en curso (el último)
    _controller = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(covariant _MonthlyCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si tras refrescar hay más (o menos) meses, la página vieja dejaría los
    // puntos desincronizados o apuntaría a un mes inexistente.
    if (widget.months.length != oldWidget.months.length) {
      _page = widget.months.length - 1;
      _controller.dispose();
      _controller = PageController(initialPage: _page);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final many = widget.months.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('MENSUAL', style: AppTypography.hudLabel()),
            const Spacer(),
            if (many)
              const Icon(Icons.swipe_outlined, size: 15, color: AppColors.textMuted),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 80,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.months.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final m = widget.months[i];
              // Cada mes se dibuja contra SU cupo: julio a 15.000 y agosto a
              // 25.000 no comparten escala. Fallback si el backend es antiguo.
              final budget = m.budgetPerPerson > 0
                  ? m.budgetPerPerson
                  : widget.monthlyBudget.toDouble();
              return _DeviationBlock(
                label: _monthLabel(m.month),
                used: m.usedFor(widget.userId),
                recommended: m.recommendedPerPerson,
                scale: budget,
                tolerance: _monthlyTolerance(budget),
              );
            },
          ),
        ),
        if (many) ...[
          const SizedBox(height: AppSpacing.sm),
          _Dots(count: widget.months.length, active: _page),
        ],
      ],
    );
  }
}

/// Etiqueta de un mes `YYYY-MM` en es-ES (p.ej. "JUNIO 2026").
String _monthLabel(String yearMonth) {
  final parts = yearMonth.split('-');
  final y = int.tryParse(parts.first) ?? 2000;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
  return EsFormat.monthYear(DateTime(y, m)).toUpperCase();
}

/// Puntos indicadores del carrusel (el activo, alargado).
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == active ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == active ? AppColors.brand : AppColors.outlineStrong,
              borderRadius: const BorderRadius.all(Radius.circular(3)),
            ),
          ),
      ],
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
    final year = summary.windowYear;
    final segments = summary.yearPlanSegments;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TOTAL $year', style: AppTypography.hudLabel()),
              const Spacer(),
              Text(
                '${EsFormat.km(totalUsed)} / ${EsFormat.km(total)} km',
                style: AppTypography.mono(size: 15, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SimpleBar(ratio: ratio, fill: AppColors.brand),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${EsFormat.km(summary.annualKmPerPerson)} km por persona este año. '
            'El exceso lo paga quien lo genera.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (summary.currentMonthKmTotal > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Este mes: ${EsFormat.km(summary.currentMonthKmTotal)} km · '
              '${EsFormat.decimal(summary.currentMonthKmPerPerson)} por persona.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          // Si el plan cambió a mitad de año, el cupo es mixto: sin esta línea
          // un total de 19.166 km parece un error.
          if (segments.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              segments.map(_segmentLabel).join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "15.000 km/año (ene–jul)" para un tramo del año con un plan distinto.
String _segmentLabel(YearPlanSegment s) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final from = months[s.fromMonth - 1];
  final to = months[s.toMonth - 1];
  final range = s.fromMonth == s.toMonth ? from : '$from–$to';
  return '${EsFormat.km(s.annualKmTotal)} km/año ($range)';
}
