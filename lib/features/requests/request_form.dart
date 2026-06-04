import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/theme/theme.dart';
import '../../core/format/es_format.dart';
import '../../data/api/api_exception.dart';
import '../../data/providers.dart';
import '../expenses/forms/form_widgets.dart';
import 'requests_controller.dart';

/// Formulario "Pedir coche" (Fase F8) → `POST /api/requests` (estado
/// `pending`). Se elige una **fecha que no sea tuya** y un mensaje opcional;
/// el backend determina el destinatario (el de prioridad ese día).
class RequestForm extends ConsumerStatefulWidget {
  const RequestForm({super.key});

  @override
  ConsumerState<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<RequestForm> {
  final _message = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final message = _message.text.trim();
      await ref
          .read(requestServiceProvider)
          .create(
            useDate: EsFormat.apiDate(_date),
            message: message.isEmpty ? null : message,
          );
      ref.invalidate(requestsControllerProvider);
      ref.invalidate(pendingRequestsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo enviar la solicitud.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: 'Pedir coche',
      submitLabel: 'ENVIAR',
      submitting: _submitting,
      errorText: _error,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Elige un día que no sea tuyo. El de prioridad lo acepta o lo rechaza.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          DateField(
            label: 'Día solicitado',
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _message,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Mensaje (opcional)'),
          ),
        ],
      ),
    );
  }
}

/// Abre el formulario "Pedir coche" en un bottom sheet. Devuelve `true` si se
/// envió la solicitud (Fase F8).
Future<bool?> openRequestForm(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RequestForm(),
    );
