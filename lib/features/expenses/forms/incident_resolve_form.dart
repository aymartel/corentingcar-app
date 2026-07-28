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

/// Hoja "Marcar como resuelta" → `PATCH /api/incidents/:id/resolve`.
///
/// Resolver significa que ya se pagó o ya se reparó: es el momento en el que el importe entra en
/// el saldo, por eso aquí se pregunta **quién puso el dinero** y se permite ajustar el importe
/// final (la factura no siempre coincide con el presupuesto).
class IncidentResolveForm extends ConsumerStatefulWidget {
  const IncidentResolveForm({super.key, required this.incident});

  final Incident incident;

  @override
  ConsumerState<IncidentResolveForm> createState() =>
      _IncidentResolveFormState();
}

class _IncidentResolveFormState extends ConsumerState<IncidentResolveForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  int? _paidBy;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final amount = widget.incident.amountEur;
    _amount = TextEditingController(
      text: amount == null ? '' : EsFormat.decimal(amount),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Pagador efectivo: el seleccionado o, por defecto, quien está resolviendo.
  int _effectivePaidBy(List<User> users) {
    final fallback = ref.read(currentUserProvider)?.id ?? users.first.id;
    final candidate = _paidBy ?? fallback;
    return users.any((u) => u.id == candidate) ? candidate : users.first.id;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final users = ref.read(allUsersProvider).asData?.value ?? const <User>[];
      final amountText = _amount.text.trim();
      final amountEur = amountText.isEmpty
          ? null
          : EsFormat.parseAmount(amountText);
      await ref
          .read(expensesServiceProvider)
          .resolveIncident(
            widget.incident.id,
            amountEur: amountEur,
            paidBy: amountEur == null || users.isEmpty
                ? null
                : _effectivePaidBy(users),
          );
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo resolver la incidencia.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = ref.watch(allUsersProvider).asData?.value ?? const <User>[];
    final hasAmount = _amount.text.trim().isNotEmpty;

    return FormSheetScaffold(
      title: 'Marcar como resuelta',
      submitting: _submitting,
      errorText: _error,
      submitLabel: 'RESOLVER',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.incident.description,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.mono(size: 16),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Importe final (opcional)',
                suffixText: '€',
                helperText: 'Si no costó nada, déjalo vacío.',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final amount = EsFormat.parseAmount(text);
                if (amount == null) return 'Importe inválido';
                if (amount < 0) return 'No puede ser negativo';
                return null;
              },
            ),
            if (hasAmount && users.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('QUIÉN LO PAGÓ', style: AppTypography.hudLabel()),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  for (final user in users)
                    _payerChip(
                      user,
                      selected: _effectivePaidBy(users) == user.id,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.incident.type.isShared
                    ? 'Se repartirá 50/50 en el saldo.'
                    : 'Lo asume ${widget.incident.responsible?.name ?? 'quien la generó'}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _payerChip(User user, {required bool selected}) {
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    return ChoiceChip(
      label: Text(user.name),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _paidBy = user.id),
      selectedColor: color,
      labelStyle: AppTypography.hudLabel(
        color: selected ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );
  }
}
