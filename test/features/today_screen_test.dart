import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/models/models.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpToday(
  WidgetTester tester,
  FakePriorityService priority, {
  FakeUsageService? usage,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        priorityServiceProvider.overrideWithValue(priority),
        requestServiceProvider.overrideWithValue(FakeRequestService()),
        carStatusServiceProvider.overrideWithValue(FakeCarStatusService()),
        if (usage != null) usageServiceProvider.overrideWithValue(usage),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const TodayScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('muestra la prioridad, la frase y las acciones', (tester) async {
    await _pumpToday(
      tester,
      FakePriorityService(
        todayResult: priorityFor(user1, conflictPhrase: 'Hoy decide Andy.'),
      ),
      usage: FakeUsageService(
        usageList: const [
          UsageLog(
            id: 1,
            userId: 1,
            date: '2026-06-10',
            startKm: 9785,
            endKm: 12480,
            totalKm: 2695,
            type: EntryType.individual,
          ),
        ],
      ),
    );

    expect(find.text('HOY TIENE PRIORIDAD'), findsOneWidget);
    expect(find.text('Andy'), findsWidgets);
    expect(find.text('Hoy decide Andy.'), findsOneWidget);
    expect(find.text('PEDIR COCHE'), findsOneWidget);
    // Cuentakilómetros bajo el coche: última cifra registrada (12.480 km).
    expect(find.text('12.480 km'), findsOneWidget);

    // Acción "Registrar uso" → abre el formulario (botón GUARDAR del sheet).
    await tester.tap(find.text('REGISTRAR USO'));
    await tester.pumpAndSettle();
    expect(find.text('GUARDAR'), findsOneWidget);
  });

  testWidgets('si es tu día, marca "ES TU DÍA"', (tester) async {
    await _pumpToday(
      tester,
      FakePriorityService(todayResult: priorityFor(user1, isMyDay: true)),
    );

    expect(find.text('ES TU DÍA'), findsOneWidget);

    // "Pedir coche" siempre disponible: abre el formulario (el día se elige
    // dentro; el backend valida si pides tu propio día).
    await tester.tap(find.text('PEDIR COCHE'));
    await tester.pumpAndSettle();
    expect(find.text('ENVIAR'), findsOneWidget);
  });

  testWidgets('error del backend muestra mensaje y reintento', (tester) async {
    await _pumpToday(
      tester,
      FakePriorityService(
        todayError: const ApiException(
          'NETWORK',
          'No hay conexión con el servidor.',
        ),
      ),
    );

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
