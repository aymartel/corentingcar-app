import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/expenses/expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpExpenses(
  WidgetTester tester,
  FakeExpensesService expenses,
) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expensesServiceProvider.overrideWithValue(expenses),
        // allUsersProvider usa authServiceProvider para resolver nombres.
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const ExpensesScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('muestra saldo combinado, gasolina, otros y lavado', (
    tester,
  ) async {
    await _pumpExpenses(
      tester,
      FakeExpensesService(summaryResult: expensesSample()),
    );

    // Acciones: las 4, incluyendo el nuevo "OTRO".
    expect(find.text('OTRO'), findsOneWidget);

    // Saldo combinado (8,50 €): Andy debe a Dennis. Aparece en frase + odómetro.
    expect(find.text('SALDO'), findsOneWidget);
    expect(find.textContaining('Andy debe'), findsOneWidget);
    expect(find.textContaining('8,50'), findsWidgets);
    // Historial de gasolina (Dennis, 25 €) y de otros (Peaje, 8 €): 2 chips COMPARTIDO.
    expect(find.text('COMPARTIDO'), findsNWidgets(2));
    expect(find.textContaining('25,00'), findsOneWidget);
    // Sección OTROS.
    expect(find.text('OTROS'), findsOneWidget);
    expect(find.text('Peaje AP-7'), findsOneWidget);
    // Lavado: último y a quién le toca.
    expect(find.text('ÚLTIMO LAVADO'), findsOneWidget);
    expect(find.text('LE TOCA A'), findsOneWidget);
    expect(find.text('Dennis'), findsWidgets);
  });

  testWidgets('sección PAGOS muestra el pago y permite eliminarlo', (
    tester,
  ) async {
    final expenses = FakeExpensesService(summaryResult: expensesSample());
    await _pumpExpenses(tester, expenses);

    // Pago de muestra: Andy → Dennis, 10 € (Bizum).
    expect(find.text('PAGOS'), findsOneWidget);
    expect(find.text('Andy → Dennis'), findsOneWidget);

    // Eliminar: icono → diálogo de confirmación → ELIMINAR.
    await tester.tap(find.byTooltip('Eliminar pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ELIMINAR'));
    await tester.pumpAndSettle();

    expect(expenses.deleteSettlementCalls, 1);
    expect(expenses.lastDeletedSettlementId, 7);
  });

  testWidgets('error del backend muestra mensaje y reintento', (tester) async {
    await _pumpExpenses(
      tester,
      FakeExpensesService(
        summaryError: const ApiException(
          'NETWORK',
          'No hay conexión con el servidor.',
        ),
      ),
    );

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
