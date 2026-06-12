import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';

/// Formulario "Registrar gasolina" (Fase F7) → `POST /api/fuel`. Siempre compartido:
/// el importe se reparte por los km que hizo cada persona desde el último repostaje,
/// según el **odómetro del cuadro** al repostar. Al teclear el importe muestra en vivo
/// cuánto le toca pagar a cada quien. Refresca GASTOS.
class FuelForm extends ConsumerStatefulWidget {
  const FuelForm({super.key});

  @override
  ConsumerState<FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends ConsumerState<FuelForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _odometer = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;
  String? _error;

  Timer? _debounce;
  int _previewToken = 0;
  bool _loadingPreview = false;
  FuelPreview? _preview;

  @override
  void initState() {
    super.initState();
    _prefillOdometer();
  }

  /// Prerrellena el odómetro con el actual (mayor `endKm`). Silencioso si no hay datos o falla la red.
  Future<void> _prefillOdometer() async {
    try {
      final last = await ref.read(usageServiceProvider).lastEndKm();
      if (!mounted || last == null) return;
      setState(() {
        if (_odometer.text.trim().isEmpty) _odometer.text = last.toString();
      });
    } catch (_) {
      // Sin conexión / sin registros: se deja en blanco y el usuario lo introduce.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _odometer.dispose();
    super.dispose();
  }

  /// Reprograma (con debounce) el cálculo del reparto al cambiar importe u odómetro.
  void _schedulePreview() {
    _debounce?.cancel();
    final amount = EsFormat.parseAmount(_amount.text);
    final odometer = int.tryParse(_odometer.text.trim());
    if (amount == null || amount <= 0 || odometer == null || odometer < 0) {
      setState(() {
        _preview = null;
        _loadingPreview = false;
      });
      return;
    }
    setState(() => _loadingPreview = true);
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetchPreview(amount, odometer),
    );
  }

  Future<void> _fetchPreview(double amount, int odometer) async {
    final token = ++_previewToken; // descarta respuestas obsoletas
    try {
      final preview = await ref
          .read(expensesServiceProvider)
          .fuelPreview(amountEur: amount, odometerKm: odometer);
      if (!mounted || token != _previewToken) return;
      setState(() {
        _preview = preview;
        _loadingPreview = false;
      });
    } catch (_) {
      // Si falla el preview, solo se oculta el desglose (no rompe el formulario).
      if (!mounted || token != _previewToken) return;
      setState(() {
        _preview = null;
        _loadingPreview = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(expensesServiceProvider)
          .addFuel(
            date: EsFormat.apiDate(_date),
            amountEur: EsFormat.parseAmount(_amount.text)!,
            odometerKm: int.parse(_odometer.text.trim()),
          );
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar la gasolina.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: 'Registrar gasolina',
      submitting: _submitting,
      errorText: _error,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DateField(
              label: 'Fecha',
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTypography.mono(size: 16),
              decoration: const InputDecoration(
                labelText: 'Importe',
                suffixText: '€',
              ),
              onChanged: (_) => _schedulePreview(),
              validator: (value) {
                final amount = EsFormat.parseAmount(value ?? '');
                if (amount == null) return 'Importe inválido';
                if (amount <= 0) return 'Debe ser mayor que 0';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _odometer,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.mono(size: 16),
              decoration: const InputDecoration(
                labelText: 'Km del cuadro',
                suffixText: 'km',
                helperText: 'Odómetro al repostar (reparte los km desde la última gasolina)',
              ),
              onChanged: (_) => _schedulePreview(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Introduce el odómetro';
                if (int.tryParse(text) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _FuelSplitBreakdown(preview: _preview, loading: _loadingPreview),
          ],
        ),
      ),
    );
  }
}

/// Desglose en vivo del reparto por km: cuánto paga cada persona del importe tecleado.
class _FuelSplitBreakdown extends StatelessWidget {
  const _FuelSplitBreakdown({required this.preview, required this.loading});

  final FuelPreview? preview;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Spinner solo mientras se calcula el primer reparto (evita parpadeo al re-teclear).
    if (loading && preview == null) {
      return Row(
        children: [
          const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Calculando reparto…', style: theme.textTheme.bodySmall),
        ],
      );
    }

    final p = preview;
    if (p == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REPARTO POR KM', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.sm),
        for (final u in p.perUser) _row(context, u),
        if (p.fallback) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sin km registrados en el periodo: repartido 50/50',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, FuelPreviewPerUser u) {
    final theme = Theme.of(context);
    final color = colorFromHex(u.user.color) ?? personColor(u.user.profile);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(u.user.name, style: theme.textTheme.bodyLarge)),
          Text(
            '${EsFormat.decimal(u.km)} km',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            EsFormat.euro(u.shareEur),
            style: AppTypography.mono(size: 15, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
