import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../common/widgets/async_views.dart';
import '../../common/widgets/glow_card.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../expenses/forms/form_widgets.dart';
import 'mileage_plan_controller.dart';

/// Hoja "Modifica tu kilometraje": elige el escalón contratado (15.000 / 20.000 /
/// 25.000 km al AÑO, o uno libre) y queda programado para el **día 1 del mes que
/// viene**. Los meses ya pasados conservan su plan, así que el histórico no se toca.
class MileagePlanSheet extends ConsumerStatefulWidget {
  const MileagePlanSheet({super.key});

  @override
  ConsumerState<MileagePlanSheet> createState() => _MileagePlanSheetState();
}

class _MileagePlanSheetState extends ConsumerState<MileagePlanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customKm = TextEditingController();
  final _customFee = TextEditingController();

  /// Escalón elegido; `null` mientras no se toque nada (se inicializa con el vigente).
  int? _selectedKm;
  bool _custom = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _customKm.dispose();
    _customFee.dispose();
    super.dispose();
  }

  /// Mes en el que entraría en vigor: el siguiente al actual (lo decide el servidor,
  /// esto es solo para el aviso).
  String get _effectiveMonthLabel {
    final now = DateTime.now();
    return EsFormat.monthYear(DateTime(now.year, now.month + 1));
  }

  Future<void> _submit(MileagePlansView view) async {
    if (_custom && !_formKey.currentState!.validate()) return;

    final int annualKmTotal;
    final double monthlyFeeEur;
    if (_custom) {
      annualKmTotal = int.parse(_customKm.text.trim());
      monthlyFeeEur = EsFormat.parseAmount(_customFee.text.trim())!;
    } else {
      final km = _selectedKm ?? view.current.annualKmTotal;
      final option = view.options
          .where((o) => o.annualKmTotal == km)
          .firstOrNull;
      if (option == null) {
        setState(() => _error = 'Elige un kilometraje.');
        return;
      }
      annualKmTotal = option.annualKmTotal;
      monthlyFeeEur = option.monthlyFeeEur;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(mileagePlanControllerProvider.notifier)
          .schedule(annualKmTotal: annualKmTotal, monthlyFeeEur: monthlyFeeEur);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo cambiar el kilometraje.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelScheduled() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(mileagePlanControllerProvider.notifier).cancelScheduled();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Cambio de kilometraje cancelado.')),
          );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cancelar el cambio.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mileagePlanControllerProvider);
    final view = async.asData?.value;

    if (view == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: async.hasError
            ? ErrorView(
                message: async.error is ApiException
                    ? (async.error! as ApiException).message
                    : 'No se pudo cargar el kilometraje.',
                onRetry: () =>
                    ref.read(mileagePlanControllerProvider.notifier).refresh(),
              )
            : const LoadingView(),
      );
    }

    final selectedKm = _custom
        ? null
        : (_selectedKm ?? view.scheduled?.annualKmTotal ?? view.current.annualKmTotal);
    final theme = Theme.of(context);

    return FormSheetScaffold(
      title: 'Modifica tu kilometraje',
      submitting: _submitting,
      errorText: _error,
      submitLabel: 'CONFIRMAR CAMBIO',
      onSubmit: () => _submit(view),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige los kilómetros que deseas',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Estarán disponibles a partir de $_effectiveMonthLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final option in view.options) ...[
              _PlanOptionCard(
                option: option,
                selected: selectedKm == option.annualKmTotal,
                onTap: () => setState(() {
                  _custom = false;
                  _selectedKm = option.annualKmTotal;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _CustomOptionCard(
              selected: _custom,
              kmController: _customKm,
              feeController: _customFee,
              onTap: () => setState(() => _custom = true),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '*Los km anuales se dividen entre 12 meses y solo se aplican a los '
              'meses restantes. El cupo de cada mes se reparte entre los dos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('HISTORIAL DE PLANES', style: AppTypography.hudLabel()),
            const SizedBox(height: AppSpacing.md),
            for (final plan in view.history) ...[
              _PlanHistoryCard(
                plan: plan,
                isCurrent: plan.id == view.current.id,
                isScheduled:
                    view.scheduled != null && plan.id == view.scheduled!.id,
                onCancel: _submitting ? null : _cancelScheduled,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una opción del catálogo, al estilo de la app del renting: km/año, sobrecoste
/// mensual y cuota resultante, más el desglose mensual y por persona.
class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MileagePlanOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = option.extraFeeEur;

    return GlowCard(
      onTap: onTap,
      glow: selected,
      accentColor: selected ? AppColors.brand : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.brand : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                EsFormat.km(option.annualKmTotal),
                style: AppTypography.odometer(size: 18),
              ),
              Text(' km/año', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                delta == 0 ? '0 €' : '+${EsFormat.euro(delta)}',
                style: AppTypography.mono(
                  size: 15,
                  weight: FontWeight.w700,
                  color: delta == 0 ? AppColors.textSecondary : AppColors.brand,
                ),
              ),
              Text(' /mes', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${EsFormat.km(option.monthlyKmTotal)} km/mes · '
                  '${EsFormat.decimal(option.monthlyKmPerPerson)} por persona',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'Cuota: ${EsFormat.euro(option.monthlyFeeEur)}/mes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (option.isCurrent || option.isScheduled) ...[
            const SizedBox(height: AppSpacing.sm),
            _Chip(
              label: option.isScheduled ? 'PROGRAMADO' : 'ACTUAL',
              color: option.isScheduled ? AppColors.warning : AppColors.brand,
            ),
          ],
        ],
      ),
    );
  }
}

/// Escalón libre: por si el renting cambia sus tarifas o contratas otro cupo.
class _CustomOptionCard extends StatelessWidget {
  const _CustomOptionCard({
    required this.selected,
    required this.kmController,
    required this.feeController,
    required this.onTap,
  });

  final bool selected;
  final TextEditingController kmController;
  final TextEditingController feeController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlowCard(
      onTap: onTap,
      glow: selected,
      accentColor: selected ? AppColors.brand : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.brand : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Otro', style: theme.textTheme.titleMedium),
            ],
          ),
          if (selected) ...[
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: kmController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.mono(size: 16),
              decoration: const InputDecoration(
                labelText: 'Kilómetros al año',
                suffixText: 'km',
              ),
              validator: (value) {
                final km = int.tryParse(value?.trim() ?? '');
                if (km == null || km <= 0) return 'Kilometraje inválido';
                if (km > 200000) return 'Demasiados km';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.mono(size: 16),
              decoration: const InputDecoration(
                labelText: 'Cuota mensual',
                suffixText: '€',
              ),
              validator: (value) {
                final fee = EsFormat.parseAmount(value?.trim() ?? '');
                if (fee == null) return 'Importe inválido';
                if (fee < 0) return 'No puede ser negativo';
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Entrada del historial: desde cuándo rige, quién lo cambió y su cuota.
class _PlanHistoryCard extends StatelessWidget {
  const _PlanHistoryCard({
    required this.plan,
    required this.isCurrent,
    required this.isScheduled,
    this.onCancel,
  });

  final MileagePlan plan;
  final bool isCurrent;
  final bool isScheduled;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = plan.effectiveMonth;
    final since = month == null
        ? 'Desde el inicio'
        : 'Desde ${EsFormat.monthYear(DateTime(int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7))))}';

    return GlowCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${EsFormat.km(plan.annualKmTotal)} km/año · '
                  '${EsFormat.euro(plan.monthlyFeeEur)}/mes',
                  style: AppTypography.mono(size: 14),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.createdBy == null
                      ? since
                      : '$since · lo cambió ${plan.createdBy!.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isScheduled) ...[
            const SizedBox(width: AppSpacing.sm),
            _Chip(label: 'PROGRAMADO', color: AppColors.warning),
            IconButton(
              tooltip: 'Cancelar el cambio',
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.danger,
              onPressed: onCancel,
            ),
          ] else if (isCurrent) ...[
            const SizedBox(width: AppSpacing.sm),
            _Chip(label: 'ACTUAL', color: AppColors.brand),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.rsm,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AppTypography.hudLabel(color: color)),
    );
  }
}

/// Abre la hoja de kilometraje. Devuelve `true` si se programó un cambio.
Future<bool?> openMileagePlanSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const MileagePlanSheet(),
    );
