import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/core/format/es_format.dart';
import 'package:coretingcar/data/models/models.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/expenses/forms/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

/// Monta un botón que abre el formulario indicado (como hacen HOY/GASTOS).
Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<Object?> Function(BuildContext) opener,
  FakeExpensesService? expenses,
  FakeUsageService? usage,
  FakeAuthService? auth,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (expenses != null)
          expensesServiceProvider.overrideWithValue(expenses),
        if (usage != null) usageServiceProvider.overrideWithValue(usage),
        // allUsersProvider (selector de pagador en el pago) usa authServiceProvider.
        if (auth != null) authServiceProvider.overrideWithValue(auth),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => opener(context),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  // El formulario de gasolina prerellena el odómetro con el último `endKm` de usos.
  FakeUsageService fuelUsage() => FakeUsageService(
    usageList: const [
      UsageLog(
        id: 1,
        userId: 1,
        date: '2026-06-04',
        startKm: 0,
        endKm: 200,
        totalKm: 200,
        type: EntryType.individual,
      ),
    ],
  );

  testWidgets('gasolina: importe inválido no envía', (tester) async {
    final expenses = FakeExpensesService();
    await _pumpLauncher(
      tester,
      opener: openFuelForm,
      expenses: expenses,
      usage: fuelUsage(),
    );

    // Sin importe → validación, no se llama al servicio.
    await tester.tap(find.text('GUARDAR'));
    await tester.pump();
    expect(find.text('Importe inválido'), findsOneWidget);
    expect(expenses.fuelCalls, 0);
  });

  testWidgets('gasolina: importe válido envía y cierra', (tester) async {
    final expenses = FakeExpensesService();
    await _pumpLauncher(
      tester,
      opener: openFuelForm,
      expenses: expenses,
      usage: fuelUsage(),
    );

    // Importe en el primer campo; el odómetro se prerellena con 200.
    await tester.enterText(find.byType(TextField).first, '20');
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(expenses.fuelCalls, 1);
    expect(find.text('GUARDAR'), findsNothing); // el sheet se cerró
  });

  testWidgets('gasolina: al teclear el importe muestra el reparto por km', (
    tester,
  ) async {
    final expenses = FakeExpensesService();
    await _pumpLauncher(
      tester,
      opener: openFuelForm,
      expenses: expenses,
      usage: fuelUsage(),
    );

    // Ya no hay selector individual/compartido (siempre compartido por km).
    expect(find.text('Compartido'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '20'); // importe
    await tester.pump(const Duration(milliseconds: 400)); // pasa el debounce
    await tester.pump(); // procesa la respuesta del preview

    expect(expenses.previewCalls, greaterThanOrEqualTo(1));
    expect(find.text('REPARTO POR KM'), findsOneWidget);
    expect(find.text('Andy'), findsOneWidget);
    expect(find.text('Dennis'), findsOneWidget);
    // 20 € → Andy 15,00 €, Dennis 5,00 €.
    expect(find.text(EsFormat.euro(15)), findsOneWidget);
    expect(find.text(EsFormat.euro(5)), findsOneWidget);
  });

  testWidgets('otro gasto: descripción vacía no envía', (tester) async {
    final expenses = FakeExpensesService();
    await _pumpLauncher(
      tester,
      opener: openOtherExpenseForm,
      expenses: expenses,
    );

    // Solo importe, sin descripción → validación, no se llama al servicio.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '15'); // importe
    await tester.tap(find.text('GUARDAR'));
    await tester.pump();

    expect(find.text('Descripción obligatoria'), findsOneWidget);
    expect(expenses.otherCalls, 0);
  });

  testWidgets('otro gasto: válido envía y cierra', (tester) async {
    final expenses = FakeExpensesService();
    await _pumpLauncher(
      tester,
      opener: openOtherExpenseForm,
      expenses: expenses,
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Peaje AP-7'); // descripción
    await tester.enterText(fields.at(1), '15'); // importe
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(expenses.otherCalls, 1);
    expect(find.text('GUARDAR'), findsNothing); // el sheet se cerró
  });

  testWidgets('pago: registra un pago de Dennis a Andy y ajusta from→to', (
    tester,
  ) async {
    final expenses = FakeExpensesService();
    await _pumpLauncher(
      tester,
      opener: openSettlementForm,
      expenses: expenses,
      auth: FakeAuthService(),
    );

    // Selector de pagador; por defecto paga el primero (Andy) → recibe Dennis.
    expect(find.text('QUIÉN PAGA'), findsOneWidget);
    expect(find.text('Recibe Dennis'), findsOneWidget);

    // Cambia el pagador a Dennis → ahora recibe Andy.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dennis'));
    await tester.pump();
    expect(find.text('Recibe Andy'), findsOneWidget);

    // Importe y guardar.
    await tester.enterText(find.byType(TextField).first, '15');
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(expenses.settlementCalls, 1);
    expect(expenses.lastSettlementFrom, 2); // Dennis
    expect(expenses.lastSettlementTo, 1); // Andy
    expect(expenses.lastSettlementAmount, 15);
    expect(find.text('GUARDAR'), findsNothing); // el sheet se cerró
  });

  testWidgets('uso: km final < inicial no envía', (tester) async {
    final usage = FakeUsageService();
    await _pumpLauncher(tester, opener: openUsageForm, usage: usage);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '100'); // inicial
    await tester.enterText(fields.at(1), '50'); // final
    await tester.tap(find.text('GUARDAR'));
    await tester.pump();

    expect(find.text('Debe ser ≥ al inicial'), findsOneWidget);
    expect(usage.createCalls, 0);
  });

  testWidgets('uso: prerellena el km inicial con el último km final', (
    tester,
  ) async {
    final usage = FakeUsageService(
      usageList: const [
        UsageLog(
          id: 2,
          userId: 1,
          date: '2026-06-04',
          startKm: 95,
          endKm: 120,
          totalKm: 25,
          type: EntryType.individual,
        ),
        UsageLog(
          id: 1,
          userId: 1,
          date: '2026-06-03',
          startKm: 0,
          endKm: 95,
          totalKm: 95,
          type: EntryType.individual,
        ),
      ],
    );
    await _pumpLauncher(tester, opener: openUsageForm, usage: usage);
    await tester.pump(); // deja completar el prerellenado async

    expect(find.text('120'), findsOneWidget);
  });
}
