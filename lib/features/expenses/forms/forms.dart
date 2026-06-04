import 'package:flutter/material.dart';

import 'fuel_form.dart';
import 'usage_form.dart';
import 'wash_form.dart';

export 'fuel_form.dart';
export 'usage_form.dart';
export 'wash_form.dart';

/// Abre el formulario de **registrar uso** en un bottom sheet. Devuelve `true`
/// si se guardó (Fase F7).
Future<bool?> openUsageForm(BuildContext context) =>
    _openForm(context, const UsageForm());

/// Abre el formulario de **registrar gasolina**. Devuelve `true` si se guardó.
Future<bool?> openFuelForm(BuildContext context) =>
    _openForm(context, const FuelForm());

/// Abre el formulario de **registrar lavado**. Devuelve `true` si se guardó.
Future<bool?> openWashForm(BuildContext context) =>
    _openForm(context, const WashForm());

Future<bool?> _openForm(BuildContext context, Widget form) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => form,
    );
