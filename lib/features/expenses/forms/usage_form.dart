import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../mileage/mileage_controller.dart';
import '../../usage_history/usage_history_controller.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';
import 'forms.dart';

/// Formulario de **uso** (Fase F7 + historial de usos).
///
/// - Sin [edit]: registra un uso (`POST /api/usage`). Si el km inicial es
///   anterior al odómetro actual (uso pasado desincronizado), se propone como
///   cambio pendiente de aprobación del otro usuario.
/// - Con [edit]: propone una edición; **toda** edición requiere aprobación.
///
/// El servidor calcula `totalKm`. Devuelve un [UsageFormOutcome] al cerrarse.
class UsageForm extends ConsumerStatefulWidget {
  const UsageForm({super.key, this.edit});

  /// Uso a editar. `null` = alta de un uso nuevo.
  final UsageLog? edit;

  @override
  ConsumerState<UsageForm> createState() => _UsageFormState();
}

class _UsageFormState extends ConsumerState<UsageForm> {
  final _formKey = GlobalKey<FormState>();
  final _startKm = TextEditingController();
  final _endKm = TextEditingController();
  late DateTime _date;
  late EntryType _type;
  bool _submitting = false;
  String? _error;

  /// Odómetro actual (mayor `endKm`) al abrir el alta. Sirve para detectar usos
  /// pasados desincronizados sin esperar al rechazo del backend.
  int? _lastEndKm;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    if (edit != null) {
      _date = DateTime.tryParse(edit.date) ?? DateTime.now();
      _type = edit.type;
      _startKm.text = edit.startKm.toString();
      _endKm.text = edit.endKm.toString();
    } else {
      _date = DateTime.now();
      _type = EntryType.individual;
      _prefillStartKm();
    }
  }

  /// Prerrellena el km inicial con el odómetro actual y lo memoriza. Silencioso
  /// si no hay datos o falla la red.
  Future<void> _prefillStartKm() async {
    try {
      final last = await ref.read(usageServiceProvider).lastEndKm();
      if (!mounted || last == null) return;
      setState(() {
        _lastEndKm = last;
        if (_startKm.text.trim().isEmpty) _startKm.text = last.toString();
      });
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

    final date = EsFormat.apiDate(_date);
    final startKm = int.parse(_startKm.text.trim());
    final endKm = int.parse(_endKm.text.trim());

    try {
      if (_isEdit) {
        await ref
            .read(usageChangeServiceProvider)
            .proposeUpdate(
              usageId: widget.edit!.id,
              date: date,
              startKm: startKm,
              endKm: endKm,
              type: _type,
            );
        _invalidate();
        _close(UsageFormOutcome.pendingApproval);
        return;
      }

      // Alta: uso pasado desincronizado → cambio pendiente de aprobación.
      if (_lastEndKm != null && startKm < _lastEndKm!) {
        await _proposeCreate(date, startKm, endKm, _lastEndKm!);
        return;
      }

      // En sincronía: registro directo.
      await ref
          .read(usageServiceProvider)
          .create(date: date, startKm: startKm, endKm: endKm, type: _type);
      _invalidate();
      _close(UsageFormOutcome.saved);
    } on ApiException catch (e) {
      // Carrera: otro uso movió el odómetro entre el prefill y el envío.
      if (!_isEdit && e.code == 'ODOMETER_INCONSISTENT') {
        await _proposeCreate(date, startKm, endKm, _lastEndKm ?? startKm);
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.message;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo registrar el uso.';
          _submitting = false;
        });
      }
    }
  }

  /// Pide confirmación y propone el alta como cambio pendiente de aprobación.
  Future<void> _proposeCreate(
    String date,
    int startKm,
    int endKm,
    int lastEndKm,
  ) async {
    final confirmed = await _confirmApproval(startKm, lastEndKm);
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _submitting = false);
      return;
    }
    try {
      await ref
          .read(usageChangeServiceProvider)
          .proposeCreate(date: date, startKm: startKm, endKm: endKm, type: _type);
      _invalidate();
      _close(UsageFormOutcome.pendingApproval);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _submitting = false;
        });
      }
    }
  }

  Future<bool?> _confirmApproval(int startKm, int lastEndKm) {
    final name = otherUserName(ref);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Necesita aprobación'),
        content: Text(
          'El km inicial (${EsFormat.km(startKm)} km) es anterior al último '
          'odómetro registrado (${EsFormat.km(lastEndKm)} km). El uso quedará '
          'pendiente hasta que $name lo apruebe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ENVIAR PARA APROBAR'),
          ),
        ],
      ),
    );
  }

  void _invalidate() {
    ref.invalidate(mileageControllerProvider);
    ref.invalidate(expensesControllerProvider);
    ref.invalidate(usageHistoryControllerProvider);
    ref.invalidate(usageChangesControllerProvider);
    ref.invalidate(pendingUsageChangesProvider);
  }

  void _close(UsageFormOutcome outcome) {
    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: _isEdit ? 'Editar uso' : 'Registrar uso',
      submitting: _submitting,
      errorText: _error,
      onSubmit: _submit,
      submitLabel: _isEdit ? 'ENVIAR PARA APROBAR' : 'GUARDAR',
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
            if (_isEdit) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'La edición se enviará al otro usuario para su aprobación.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
