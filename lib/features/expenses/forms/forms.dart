import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import 'fuel_form.dart';
import 'other_expense_form.dart';
import 'usage_form.dart';
import 'wash_form.dart';

export 'fuel_form.dart';
export 'other_expense_form.dart';
export 'usage_form.dart';
export 'wash_form.dart';

/// Resultado del formulario de uso: registro aplicado directamente (`saved`) o
/// cambio enviado para aprobación del otro usuario (`pendingApproval`).
enum UsageFormOutcome { saved, pendingApproval }

/// Abre el formulario de **uso** en un bottom sheet. Sin [edit] crea un uso
/// (Fase F7); con [edit] propone una edición (requiere aprobación). Devuelve el
/// [UsageFormOutcome] o `null` si se cerró sin guardar.
Future<UsageFormOutcome?> openUsageForm(BuildContext context, {UsageLog? edit}) =>
    _openForm<UsageFormOutcome>(context, UsageForm(edit: edit));

/// Abre el formulario de **registrar gasolina**. Devuelve `true` si se guardó.
Future<bool?> openFuelForm(BuildContext context) =>
    _openForm<bool>(context, const FuelForm());

/// Abre el formulario de **registrar lavado**. Devuelve `true` si se guardó.
Future<bool?> openWashForm(BuildContext context) =>
    _openForm<bool>(context, const WashForm());

/// Abre el formulario de **registrar otro gasto**. Devuelve `true` si se guardó.
Future<bool?> openOtherExpenseForm(BuildContext context) =>
    _openForm<bool>(context, const OtherExpenseForm());

Future<T?> _openForm<T>(BuildContext context, Widget form) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => form,
    );

/// Abre el formulario de uso (crear) y muestra el aviso adecuado: registro
/// directo o cambio enviado para aprobación. Atajo para HOY y GASTOS.
Future<void> handleUsageForm(BuildContext context) async {
  final outcome = await openUsageForm(context);
  if (outcome == null || !context.mounted) return;
  final message = outcome == UsageFormOutcome.pendingApproval
      ? 'Cambio enviado para aprobación.'
      : 'Uso registrado.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
