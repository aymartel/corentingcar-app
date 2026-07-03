import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/mileage/mileage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpMileage(WidgetTester tester, FakeUsageService usage) async {
  // Viewport alto para que el ListView construya todas las tarjetas.
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [usageServiceProvider.overrideWithValue(usage)],
      child: MaterialApp(theme: AppTheme.dark(), home: const MileageScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('muestra barras por persona y formato es-ES', (tester) async {
    await _pumpMileage(
      tester,
      FakeUsageService(mileageResult: mileageSample()),
    );

    expect(find.text('Andy'), findsWidgets);
    expect(find.text('Dennis'), findsWidgets);
    // Usados / límite con separador de miles (es-ES) sin decimales.
    expect(find.text('6.240 / 7.500 km'), findsOneWidget);
    expect(find.text('8.430 / 7.500 km'), findsOneWidget);
    // Resumen anual (15.000 total).
    expect(find.textContaining('15.000 km'), findsWidgets);
    // Dos barras por persona: ANUAL (±500) y MENSUAL (±50, carrusel).
    expect(find.text('ANUAL'), findsNWidgets(2));
    expect(find.text('MENSUAL'), findsNWidgets(2));
    // Anual: Andy +240 (verde, dentro de ±500); Dennis +2.430 (rojo).
    expect(find.text('240 km por encima'), findsOneWidget);
    expect(find.text('2.430 km por encima'), findsOneWidget);
    // Mensual: por defecto muestra el mes en curso (julio).
    expect(find.text('JULIO 2026'), findsNWidgets(2));
    // Julio: Andy 500 vs 625 → 125 por debajo; Dennis 900 vs 625 → 275 por encima.
    expect(find.text('125 km por debajo'), findsOneWidget);
    expect(find.text('275 km por encima'), findsOneWidget);
  });

  testWidgets('aviso de exceso visible con los km correctos', (tester) async {
    await _pumpMileage(
      tester,
      FakeUsageService(mileageResult: mileageSample()),
    );

    expect(find.text('CUPO SUPERADO'), findsOneWidget);
    expect(find.textContaining('930 km de exceso'), findsOneWidget);
  });

  testWidgets('km compartidos como dato 50/50', (tester) async {
    await _pumpMileage(
      tester,
      FakeUsageService(mileageResult: mileageSample()),
    );

    expect(find.text('VIAJES JUNTOS'), findsOneWidget);
    expect(find.textContaining('50/50'), findsOneWidget);
    expect(find.text('120,5 km'), findsWidgets);
  });

  testWidgets('error del backend muestra mensaje y reintento', (tester) async {
    await _pumpMileage(
      tester,
      FakeUsageService(
        mileageError: const ApiException(
          'NETWORK',
          'No hay conexión con el servidor.',
        ),
      ),
    );

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
