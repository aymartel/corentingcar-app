import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../login/session_controller.dart';
import '../expenses_controller.dart';
import 'form_widgets.dart';

/// Formulario "Registrar pago" → `POST /api/settlements`. Pago directo de una
/// persona a otra (saldar cuentas), sin vincular a un gasto: ajusta el saldo.
/// Con [initialFromUserId] / [initialAmount] se prerrellena para "saldar" la deuda.
class SettlementForm extends ConsumerStatefulWidget {
  const SettlementForm({super.key, this.initialFromUserId, this.initialAmount});

  /// Pagador inicial sugerido (p. ej. el deudor, al saldar desde el saldo).
  final int? initialFromUserId;

  /// Importe inicial sugerido (p. ej. la deuda actual).
  final double? initialAmount;

  @override
  ConsumerState<SettlementForm> createState() => _SettlementFormState();
}

class _SettlementFormState extends ConsumerState<SettlementForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  int? _fromUserId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fromUserId = widget.initialFromUserId;
    final amount = widget.initialAmount;
    if (amount != null && amount > 0) {
      _amount.text = amount.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Pagador efectivo: el seleccionado, o el inicial, o el usuario actual, o el primero.
  int _effectiveFrom(List<User> users) {
    final fallback = ref.read(currentUserProvider)?.id ?? users.first.id;
    final candidate = _fromUserId ?? widget.initialFromUserId ?? fallback;
    return users.any((u) => u.id == candidate) ? candidate : users.first.id;
  }

  Future<void> _submit(List<User> users) async {
    if (!_formKey.currentState!.validate()) return;
    final from = _effectiveFrom(users);
    final to = users.firstWhere((u) => u.id != from);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(expensesServiceProvider)
          .addSettlement(
            fromUserId: from,
            toUserId: to.id,
            date: EsFormat.apiDate(_date),
            amountEur: EsFormat.parseAmount(_amount.text)!,
            note: _note.text,
          );
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar el pago.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).asData?.value;

    return FormSheetScaffold(
      title: 'Registrar pago',
      submitting: _submitting,
      errorText: _error,
      onSubmit: users == null ? () {} : () => _submit(users),
      child: users == null || users.length < 2
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          : _form(context, users),
    );
  }

  Widget _form(BuildContext context, List<User> users) {
    final from = _effectiveFrom(users);
    final to = users.firstWhere((u) => u.id != from);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('QUIÉN PAGA', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final u in users) ...[
                _payerChip(u, selected: u.id == from),
                if (u != users.last) const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Recibe ${to.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DateField(
            label: 'Fecha',
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          TextFormField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Bizum, efectivo…',
            ),
          ),
        ],
      ),
    );
  }

  Widget _payerChip(User user, {required bool selected}) {
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    return ChoiceChip(
      label: Text(user.name),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _fromUserId = user.id),
      selectedColor: color,
      labelStyle: AppTypography.hudLabel(
        color: selected ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );
  }
}
