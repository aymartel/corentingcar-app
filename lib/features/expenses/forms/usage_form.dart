import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../mileage/mileage_controller.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';

/// Formulario "Registrar uso" (Fase F7) → `POST /api/usage`. El servidor
/// calcula `totalKm`. Tras guardar, refresca KILÓMETROS y GASTOS.
class UsageForm extends ConsumerStatefulWidget {
  const UsageForm({super.key});

  @override
  ConsumerState<UsageForm> createState() => _UsageFormState();
}

class _UsageFormState extends ConsumerState<UsageForm> {
  final _formKey = GlobalKey<FormState>();
  final _startKm = TextEditingController();
  final _endKm = TextEditingController();
  DateTime _date = DateTime.now();
  EntryType _type = EntryType.individual;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillStartKm();
  }

  /// Prerrellena el km inicial con el odómetro actual (último km final), así el
  /// usuario solo escribe el final. Silencioso si no hay datos o falla la red.
  Future<void> _prefillStartKm() async {
    try {
      final last = await ref.read(usageServiceProvider).lastEndKm();
      if (mounted && last != null && _startKm.text.trim().isEmpty) {
        _startKm.text = last.toString();
      }
    } catch (_) {
      // Sin conexión / sin registros: se deja en blanco.
    }
  }

  @override
  void dispose() {
    _startKm.dispose();
    _endKm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(usageServiceProvider)
          .create(
            date: EsFormat.apiDate(_date),
            startKm: int.parse(_startKm.text.trim()),
            endKm: int.parse(_endKm.text.trim()),
            type: _type,
          );
      ref.invalidate(mileageControllerProvider);
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar el uso.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: 'Registrar uso',
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startKm,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.mono(size: 16),
                    decoration: const InputDecoration(labelText: 'Km inicial'),
                    validator: _validateKm,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _endKm,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.mono(size: 16),
                    decoration: const InputDecoration(labelText: 'Km final'),
                    validator: _validateEndKm,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            EntryTypeSelector(
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateKm(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obligatorio';
    if (int.tryParse(text) == null) return 'Número inválido';
    return null;
  }

  String? _validateEndKm(String? value) {
    final base = _validateKm(value);
    if (base != null) return base;
    final end = int.tryParse(value!.trim());
    final start = int.tryParse(_startKm.text.trim());
    if (start != null && end != null && end < start) {
      return 'Debe ser ≥ al inicial';
    }
    return null;
  }
}
