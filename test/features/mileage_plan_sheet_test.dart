import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/rules/mileage_plan_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpSheet(
  WidgetTester tester,
  FakeMileagePlanService service,
) async {
  // Viewport alto: la hoja lleva las 3 opciones, "Otro" y el historial.
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [mileagePlanServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: MileagePlanSheet()),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('pinta los 3 escalones con su sobrecoste y su cuota', (
    tester,
  ) async {
    await _pumpSheet(tester, FakeMileagePlanService());

    expect(find.text('MODIFICA TU KILOMETRAJE'), findsOneWidget);
    expect(find.text('Elige los kilómetros que deseas'), findsOneWidget);

    // Los escalones son ANUALES.
    expect(find.text('15.000'), findsWidgets);
    expect(find.text('20.000'), findsWidgets);
    expect(find.text('25.000'), findsWidgets);
    // Sobrecoste respecto al más barato, como en la app del renting.
    // (textContaining: `intl` usa espacio duro antes del €.)
    expect(find.textContaining('+30,00'), findsOneWidget);
    expect(find.textContaining('+70,00'), findsOneWidget);
    // 25.000 / 12 = 2.083 al mes; por persona, 1.041,7 (EsFormat.decimal, 1 decimal).
    expect(find.text('2.083 km/mes · 1.041,7 por persona'), findsOneWidget);
    expect(find.textContaining('Cuota: 425,00'), findsOneWidget);
    // El plan vigente va marcado.
    expect(find.text('ACTUAL'), findsWidgets);
  });

  testWidgets('elegir un escalón y confirmar lo programa', (tester) async {
    final service = FakeMileagePlanService();
    await _pumpSheet(tester, service);

    await tester.tap(find.text('25.000').first);
    await tester.pump();
    await tester.tap(find.text('CONFIRMAR CAMBIO'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(service.scheduleCalls, 1);
    expect(service.lastAnnualKmTotal, 25000);
    expect(service.lastMonthlyFeeEur, 425);
  });

  testWidgets('"Otro": kilometraje inválido no envía', (tester) async {
    final service = FakeMileagePlanService();
    await _pumpSheet(tester, service);

    await tester.tap(find.text('Otro'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.tap(find.text('CONFIRMAR CAMBIO'));
    await tester.pump();

    expect(find.text('Kilometraje inválido'), findsOneWidget);
    expect(service.scheduleCalls, 0);
  });

  testWidgets('"Otro" con valores válidos envía km y cuota libres', (
    tester,
  ) async {
    final service = FakeMileagePlanService();
    await _pumpSheet(tester, service);

    await tester.tap(find.text('Otro'));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30000');
    await tester.enterText(fields.at(1), '470,50');
    await tester.tap(find.text('CONFIRMAR CAMBIO'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(service.scheduleCalls, 1);
    expect(service.lastAnnualKmTotal, 30000);
    expect(service.lastMonthlyFeeEur, 470.5);
  });

  testWidgets('el cambio programado sale en el historial y se puede cancelar', (
    tester,
  ) async {
    final service = FakeMileagePlanService(
      result: mileagePlansSample(scheduled: scheduledPlanSample),
    );
    await _pumpSheet(tester, service);

    expect(find.text('PROGRAMADO'), findsWidgets);
    expect(
      find.textContaining('Desde agosto 2026 · lo cambió Andy'),
      findsOneWidget,
    );
    // La línea base se etiqueta "desde el inicio" (no tiene mes de efecto).
    expect(find.textContaining('Desde el inicio'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(service.cancelCalls, 1);
  });

  testWidgets('error del backend muestra mensaje y reintento', (tester) async {
    await _pumpSheet(
      tester,
      FakeMileagePlanService(
        error: const ApiException('NETWORK', 'No hay conexión con el servidor.'),
      ),
    );

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
