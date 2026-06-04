import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/providers.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';

/// Formulario "Registrar lavado" (Fase F7) → `POST /api/washes`. El lavado
/// alterna (uno cada uno). El coste es opcional. Refresca GASTOS.
class WashForm extends ConsumerStatefulWidget {
  const WashForm({super.key});

  @override
  ConsumerState<WashForm> createState() => _WashFormState();
}

class _WashFormState extends ConsumerState<WashForm> {
  final _formKey = GlobalKey<FormState>();
  final _cost = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _cost.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final costText = _cost.text.trim();
      await ref
          .read(expensesServiceProvider)
          .addWash(
            date: EsFormat.apiDate(_date),
            costEur: costText.isEmpty ? null : EsFormat.parseAmount(costText),
          );
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar el lavado.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: 'Registrar lavado',
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
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTypography.mono(size: 16),
              decoration: const InputDecoration(
                labelText: 'Coste (opcional)',
                suffixText: '€',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final cost = EsFormat.parseAmount(text);
                if (cost == null) return 'Importe inválido';
                if (cost < 0) return 'No puede ser negativo';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
