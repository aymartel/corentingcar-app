import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/calendar/calendar_screen.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpCalendar(
  WidgetTester tester,
  FakePriorityService priority,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        priorityServiceProvider.overrideWithValue(priority),
        requestServiceProvider.overrideWithValue(FakeRequestService()),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const CalendarScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('pinta el mes con días, leyenda y cabecera', (tester) async {
    await _pumpCalendar(tester, FakePriorityService());

    // Cabecera de días y leyenda en español.
    expect(find.text('L'), findsWidgets);
    expect(find.text('Andy'), findsOneWidget);
    expect(find.text('Dennis'), findsOneWidget);
    expect(find.text('Cesión'), findsOneWidget);

    // Días del mes presentes (1 y 15).
    expect(find.text('1'), findsWidgets);
    expect(find.text('15'), findsWidgets);
  });

  testWidgets('tocar un día abre el detalle', (tester) async {
    await _pumpCalendar(tester, FakePriorityService());

    // El día 15 es una cesión (request_accepted en el fake).
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    expect(find.text('PRIORIDAD'), findsOneWidget);
    expect(find.text('Solicitud aceptada'), findsOneWidget);
  });

  testWidgets('día del otro sin solicitud → "Pedir coche" crea la solicitud', (
    tester,
  ) async {
    final requestService = FakeRequestService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priorityServiceProvider.overrideWithValue(FakePriorityService()),
          requestServiceProvider.overrideWithValue(requestService),
          currentUserProvider.overrideWithValue(user1),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const CalendarScreen()),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    // Día 2 (par) → prioridad user2 (Dennis) → no es mi día → "Pedir coche".
    await tester.tap(find.text('2').first);
    await tester.pumpAndSettle();
    expect(find.text('Pedir coche'), findsOneWidget);

    await tester.tap(find.text('Pedir coche'));
    await tester.pumpAndSettle();
    expect(requestService.createCalls, 1);
  });

  testWidgets('navegar de mes recarga los datos', (tester) async {
    final priority = FakePriorityService();
    await _pumpCalendar(tester, priority);
    final callsAfterFirst = priority.calendarCalls;

    await tester.tap(find.byTooltip('Mes siguiente'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(priority.calendarCalls, greaterThan(callsAfterFirst));
  });

  testWidgets('error del backend muestra mensaje y reintento', (tester) async {
    await _pumpCalendar(
      tester,
      FakePriorityService(
        calendarError: const ApiException(
          'NETWORK',
          'No hay conexión con el servidor.',
        ),
      ),
    );

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
