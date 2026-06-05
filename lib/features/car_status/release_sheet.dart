import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../expenses/expenses_controller.dart';
import '../expenses/forms/form_widgets.dart';
import '../mileage/mileage_controller.dart';
import 'car_status_controller.dart';

/// Abre el modal **fusionado** "Lo dejo libre" (Fase F12): registra el uso del
/// viaje (km opcionales) y libera el coche con su parqueo. Devuelve `true` si se
/// liberó.
Future<bool?> openReleaseSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ReleaseSheet(),
    );

/// Modal fusionado de "Lo dejo libre" (Fase F12): **uso + parqueo + nota**.
/// Al confirmar: si hay km → `POST /api/usage`; **luego** libera el coche. Si el
/// uso falla (p. ej. odómetro incoherente), **no** libera y muestra el error.
class ReleaseSheet extends ConsumerStatefulWidget {
  const ReleaseSheet({super.key});

  @override
  ConsumerState<ReleaseSheet> createState() => _ReleaseSheetState();
}

class _ReleaseSheetState extends ConsumerState<ReleaseSheet> {
  final _startKm = TextEditingController();
  final _endKm = TextEditingController();
  final _note = TextEditingController();
  EntryType _type = EntryType.individual;
  ParkingSpot? _parking;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillStartKm();
  }

  /// Prerrellena el km inicial con el odómetro actual (último km final).
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
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final startText = _startKm.text.trim();
    final endText = _endKm.text.trim();
    final hasKm = startText.isNotEmpty || endText.isNotEmpty;

    // Validación (parqueo obligatorio; km coherentes si se rellenan).
    if (_parking == null) {
      setState(() => _error = 'Elige dónde dejas el coche.');
      return;
    }
    final note = _note.text.trim();
    if (_parking == ParkingSpot.other && note.isEmpty) {
      setState(() => _error = 'Indica dónde lo dejas (descripción).');
      return;
    }
    int? start;
    int? end;
    if (hasKm) {
      start = int.tryParse(startText);
      end = int.tryParse(endText);
      if (start == null || end == null) {
        setState(() => _error = 'Completa el km inicial y el final.');
        return;
      }
      if (end < start) {
        setState(() => _error = 'El km final debe ser ≥ al inicial.');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // 1) Si hubo viaje, registrar el uso PRIMERO (valida el odómetro).
      if (hasKm) {
        await ref
            .read(usageServiceProvider)
            .create(
              date: EsFormat.apiDate(DateTime.now()),
              startKm: start!,
              endKm: end!,
              type: _type,
            );
        ref.invalidate(mileageControllerProvider);
        ref.invalidate(expensesControllerProvider);
      }
      // 2) Liberar el coche (solo si el uso no falló).
      await ref
          .read(carStatusProvider.notifier)
          .release(parking: _parking!, note: note.isEmpty ? null : note);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo dejar libre el coche.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _parking == ParkingSpot.other;
    return FormSheetScaffold(
      title: 'Lo dejo libre',
      submitting: _submitting,
      errorText: _error,
      submitLabel: 'DEJAR LIBRE',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'KM DEL VIAJE (OPCIONAL)',
            style: AppTypography.hudLabel(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startKm,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.mono(size: 16),
                  decoration: const InputDecoration(labelText: 'Km inicial'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _endKm,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.mono(size: 16),
                  decoration: const InputDecoration(labelText: 'Km final'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          EntryTypeSelector(
            value: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('PARQUEO', style: AppTypography.hudLabel()),
          const SizedBox(height: AppSpacing.sm),
          _ParkingToggle(
            value: _parking,
            onChanged: (p) => setState(() => _parking = p),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            // Al cambiar la nota, refresca por si afecta a la validación de "Otro".
            onChanged: isOther ? (_) => setState(() {}) : null,
            decoration: InputDecoration(
              labelText: isOther ? 'Descripción (obligatoria)' : 'Nota (opcional)',
              hintText: isOther ? 'p. ej. garaje del trabajo' : 'p. ej. plaza 12',
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle obligatorio del parqueo: "Casa de Andy" / "Casa de Dennis".
class _ParkingToggle extends StatelessWidget {
  const _ParkingToggle({required this.value, required this.onChanged});

  final ParkingSpot? value;
  final ValueChanged<ParkingSpot> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _chip(ParkingSpot.user1, 'Casa de Andy', AppColors.user1),
        _chip(ParkingSpot.user2, 'Casa de Dennis', AppColors.user2),
        _chip(ParkingSpot.other, 'Otro', AppColors.info),
      ],
    );
  }

  Widget _chip(ParkingSpot spot, String label, Color color) {
    final selected = value == spot;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onChanged(spot),
      selectedColor: color,
      labelStyle: AppTypography.hudLabel(
        color: selected ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );
  }
}
