import 'package:flutter/material.dart';

import '../../../common/theme/theme.dart';
import '../../../core/format/es_format.dart';
import '../../../data/models/models.dart';

/// Contenedor común de los formularios en bottom sheet (Fase F7): respeta el
/// teclado, título estilo HUD, error en español y botón de envío con carga.
class FormSheetScaffold extends StatelessWidget {
  const FormSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.submitting,
    required this.onSubmit,
    this.errorText,
    this.submitLabel = 'GUARDAR',
  });

  final String title;
  final Widget child;
  final bool submitting;
  final String? errorText;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title.toUpperCase(), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            child,
            if (errorText != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
                      ),
                    )
                  : Text(submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de fecha: abre el selector y muestra la fecha en es-ES (mono).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rmd,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(now.year + 1, 12, 31),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(EsFormat.date(value), style: AppTypography.mono(size: 15)),
      ),
    );
  }
}

/// Selector individual/compartido (uso y gasolina).
class EntryTypeSelector extends StatelessWidget {
  const EntryTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EntryType value;
  final ValueChanged<EntryType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIPO', style: AppTypography.hudLabel()),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _chip(EntryType.individual, 'Individual'),
            const SizedBox(width: AppSpacing.md),
            _chip(EntryType.shared, 'Compartido'),
          ],
        ),
      ],
    );
  }

  Widget _chip(EntryType type, String label) {
    final selected = value == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onChanged(type),
      selectedColor: AppColors.brand,
      labelStyle: AppTypography.hudLabel(
        color: selected ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );
  }
}
