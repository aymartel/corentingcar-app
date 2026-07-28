import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/brand/brand.dart';
import '../../common/widgets/glow_card.dart';
import '../../config/env.dart';
import '../../core/constants/app_constants.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../login/session_controller.dart';
import 'mileage_plan_sheet.dart';
import 'rules_controller.dart';

/// Pantalla REGLAS / Ajustes (Fase F9): resumen **de solo lectura** del acuerdo
/// (`GET /api/rules`) y ajustes básicos (perfil activo, versión, entorno y
/// cerrar sesión). No se editan reglas desde la app.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('REGLAS')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('EL ACUERDO', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.md),
          const _RulesSection(),
          const SizedBox(height: AppSpacing.xl),
          Text('AJUSTES', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.md),
          if (user != null) ...[
            _ProfileCard(user: user),
            const SizedBox(height: AppSpacing.md),
          ],
          const _EnvironmentCard(),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
  }
}

/// Resumen de reglas (async): los valores económicos y de km vienen del backend.
class _RulesSection extends ConsumerWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rulesProvider);
    final rules = async.asData?.value;

    if (rules != null) return _RulesCards(rules: rules);
    if (async.hasError) {
      final error = async.error;
      return ErrorView(
        message: error is ApiException
            ? error.message
            : 'No se pudieron cargar las reglas.',
        onRetry: () => ref.invalidate(rulesProvider),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: LoadingView(),
    );
  }
}

class _RulesCards extends StatelessWidget {
  const _RulesCards({required this.rules});

  final Rules rules;

  /// "Programado: 25.000 km/año desde agosto 2026" si hay un cambio pendiente.
  String? _scheduledLabel() {
    final scheduled = rules.scheduledKmPlan;
    final month = scheduled?.effectiveMonth;
    if (scheduled == null || month == null) return null;
    final date = DateTime(
      int.parse(month.substring(0, 4)),
      int.parse(month.substring(5, 7)),
    );
    return 'Programado: ${EsFormat.km(scheduled.annualKmTotal)} km/año '
        'desde ${EsFormat.monthYear(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final anchor = DateTime.tryParse(rules.anchorDate);
    final anchorLabel = anchor == null
        ? rules.anchorDate
        : EsFormat.date(anchor);
    final plan = rules.kmPlan;
    final scheduledLabel = _scheduledLabel();

    return Column(
      children: [
        _RuleCard(
          icon: Icons.euro_outlined,
          title: 'Cuota mensual',
          value: '${EsFormat.euro(rules.monthlyFeeEur)}/mes',
          subtitle:
              '${EsFormat.euro(rules.feePerPerson)} por persona '
              '(${rules.feeSplitPct.toStringAsFixed(0)}/${rules.feeSplitPct.toStringAsFixed(0)})',
        ),
        _RuleCard(
          icon: Icons.speed_outlined,
          title: 'Kilómetros',
          value: '${EsFormat.km(rules.annualKmTotal)} km/año',
          subtitle: plan == null
              ? '${EsFormat.km(rules.annualKmPerPerson)} km por persona · '
                    'el exceso lo paga quien lo genera'
              : '${EsFormat.km(rules.annualKmPerPerson)} km por persona · '
                    '${EsFormat.km(plan.monthlyKmTotal)} km/mes '
                    '(${EsFormat.decimal(plan.monthlyKmPerPerson)} cada uno)',
          // Solo es editable si el backend ya sirve el plan (app nueva / backend viejo).
          onTap: plan == null ? null : () => openMileagePlanSheet(context),
          footer: scheduledLabel,
        ),
        _RuleCard(
          icon: Icons.swap_horiz,
          title: 'Prioridad',
          value: 'Alterna un día cada uno',
          subtitle:
              'Continua desde el $anchorLabel (no se reinicia por semana)',
        ),
        _RuleCard(
          icon: Icons.local_gas_station_outlined,
          title: 'Gasolina',
          value: 'La paga quien consume',
          subtitle: 'En viaje compartido se divide 50/50',
        ),
        _RuleCard(
          icon: Icons.local_car_wash_outlined,
          title: 'Lavado',
          value: 'Alterna: uno cada uno',
          subtitle: 'Se muestra el último y a quién le toca',
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  /// Si se indica, la tarjeta es pulsable (y muestra el chevrón).
  final VoidCallback? onTap;

  /// Línea extra destacada bajo el subtítulo (p.ej. un cambio programado).
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Si el valor empieza por dígito, se muestra en mono (cifras).
    final isNumeric = value.isNotEmpty && RegExp(r'^\d').hasMatch(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlowCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brand, size: 22),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: AppTypography.hudLabel()),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: isNumeric
                        ? AppTypography.odometer(size: 18)
                        : theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      footer!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlowCard(
      accentColor: colorFromHex(user.color) ?? personColor(user.profile),
      child: Row(
        children: [
          PersonAvatar(
            name: user.name,
            profile: user.profile,
            color: colorFromHex(user.color),
            size: 48,
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PERFIL ACTIVO', style: AppTypography.hudLabel()),
              const SizedBox(height: AppSpacing.xs),
              Text(user.name, style: theme.textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard();

  @override
  Widget build(BuildContext context) {
    final url = Env.apiUrl;
    final isDev = url.contains('localhost') || url.contains('10.0.2.2');

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Versión', value: AppConstants.appVersion),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: 'Entorno',
            value: isDev ? 'Desarrollo' : 'Producción',
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Base URL', value: url),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label.toUpperCase(), style: AppTypography.hudLabel()),
        ),
        Expanded(child: Text(value, style: AppTypography.mono(size: 13))),
      ],
    );
  }
}
