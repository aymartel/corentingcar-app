import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';

/// Formulario "Registrar otro gasto" (peaje, líquido, etc.) → `POST /api/other-expenses`.
/// Compartido se reparte 50/50; individual lo paga quien lo registra. Refresca GASTOS.
class OtherExpenseForm extends ConsumerStatefulWidget {
  const OtherExpenseForm({super.key});

  @override
  ConsumerState<OtherExpenseForm> createState() => _OtherExpenseFormState();
}

class _OtherExpenseFormState extends ConsumerState<OtherExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  EntryType _type = EntryType.shared;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
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
          .addOtherExpense(
            date: EsFormat.apiDate(_date),
            amountEur: EsFormat.parseAmount(_amount.text)!,
            type: _type,
            description: _description.text.trim(),
          );
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar el gasto.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: 'Registrar otro gasto',
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
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Peaje, líquido, multa…',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Descripción obligatoria';
                return null;
              },
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
