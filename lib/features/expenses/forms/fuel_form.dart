import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';

/// Formulario "Registrar gasolina" (Fase F7) → `POST /api/fuel`. Compartido se
/// reparte 50/50; individual lo paga quien consume. Refresca GASTOS.
class FuelForm extends ConsumerStatefulWidget {
  const FuelForm({super.key});

  @override
  ConsumerState<FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends ConsumerState<FuelForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  EntryType _type = EntryType.individual;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
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
          .read(expensesServiceProvider)
          .addFuel(
            date: EsFormat.apiDate(_date),
            amountEur: EsFormat.parseAmount(_amount.text)!,
            type: _type,
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
              validator: (value) {
                final amount = EsFormat.parseAmount(value ?? '');
                if (amount == null) return 'Importe inválido';
                if (amount <= 0) return 'Debe ser mayor que 0';
                return null;
              },
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
}
