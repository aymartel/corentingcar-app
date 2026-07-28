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

/// Formulario de **incidencia** (multa, golpe, avería…) → `POST/PATCH /api/incidents`.
///
/// El importe es OPCIONAL: se puede registrar el día que pasa y ponerle el coste después. El
/// dinero no entra en el saldo hasta marcarla resuelta, así que aquí no se pregunta quién pagó.
class IncidentForm extends ConsumerStatefulWidget {
  const IncidentForm({super.key, this.edit});

  /// Si se indica, el formulario edita esa incidencia en vez de crear una nueva.
  final Incident? edit;

  @override
  ConsumerState<IncidentForm> createState() => _IncidentFormState();
}

class _IncidentFormState extends ConsumerState<IncidentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late DateTime _date;
  late IncidentKind _kind;
  late EntryType _type;
  int? _responsibleUserId;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    _description = TextEditingController(text: edit?.description ?? '');
    _amount = TextEditingController(
      text: edit?.amountEur == null ? '' : EsFormat.decimal(edit!.amountEur!),
    );
    _date = edit == null
        ? DateTime.now()
        : (DateTime.tryParse(edit.date) ?? DateTime.now());
    _kind = edit?.kind ?? IncidentKind.damage;
    _type = edit?.type ?? EntryType.shared;
    _responsibleUserId = edit?.responsible?.id;
  }

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
      final amountText = _amount.text.trim();
      final amountEur = amountText.isEmpty
          ? null
          : EsFormat.parseAmount(amountText);
      final service = ref.read(expensesServiceProvider);
      final edit = widget.edit;
      // Se envía explícito para que al EDITAR no dependa de quién registró la incidencia.
      final users = ref.read(allUsersProvider).asData?.value ?? const <User>[];
      final responsibleUserId = _type == EntryType.individual && users.isNotEmpty
          ? _effectiveResponsible(users)
          : null;
      if (edit == null) {
        await service.addIncident(
          date: EsFormat.apiDate(_date),
          kind: _kind,
          description: _description.text.trim(),
          type: _type,
          amountEur: amountEur,
          responsibleUserId: responsibleUserId,
        );
      } else {
        await service.updateIncident(
          edit.id,
          date: EsFormat.apiDate(_date),
          kind: _kind,
          description: _description.text.trim(),
          type: _type,
          amountEur: amountEur,
          responsibleUserId: responsibleUserId,
        );
      }
      ref.invalidate(expensesControllerProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar la incidencia.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = ref.watch(allUsersProvider).asData?.value ?? const <User>[];

    return FormSheetScaffold(
      title: _isEdit ? 'Editar incidencia' : 'Registrar incidencia',
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
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Rayada puerta trasera, multa zona azul…',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Descripción obligatoria'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.mono(size: 16),
              decoration: const InputDecoration(
                labelText: 'Importe (opcional)',
                suffixText: '€',
                helperText: 'Puedes dejarlo vacío y ponerlo cuando lo sepas.',
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
            const SizedBox(height: AppSpacing.lg),
            Text('TIPO DE INCIDENCIA', style: AppTypography.hudLabel()),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                for (final kind in IncidentKind.values)
                  ChoiceChip(
                    label: Text(kind.label),
                    selected: _kind == kind,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _kind = kind),
                    selectedColor: AppColors.brand,
                    labelStyle: AppTypography.hudLabel(
                      color: _kind == kind
                          ? AppColors.onAccent
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('QUIÉN LA ASUME', style: AppTypography.hudLabel()),
            const SizedBox(height: AppSpacing.sm),
            EntryTypeSelector(
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            // El responsable solo tiene sentido en un reparto individual.
            if (_type == EntryType.individual && users.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('LA GENERÓ', style: AppTypography.hudLabel()),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  for (final user in users)
                    _responsibleChip(
                      user,
                      selected: _effectiveResponsible(users) == user.id,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Su coste lo asume esa persona, aunque lo pague la otra.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Se registra como ABIERTA. El importe entrará en el saldo cuando la marques '
                'como resuelta y digas quién puso el dinero.',
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

  /// Responsable efectivo: el elegido o, por defecto, el usuario actual (que es también lo que
  /// asume el backend si no se envía).
  int _effectiveResponsible(List<User> users) {
    final fallback = ref.read(currentUserProvider)?.id ?? users.first.id;
    final candidate = _responsibleUserId ?? fallback;
    return users.any((u) => u.id == candidate) ? candidate : users.first.id;
  }

  Widget _responsibleChip(User user, {required bool selected}) {
    final color = colorFromHex(user.color) ?? personColor(user.profile);
    return ChoiceChip(
      label: Text(user.name),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _responsibleUserId = user.id),
      selectedColor: color,
      labelStyle: AppTypography.hudLabel(
        color: selected ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );
  }
}
