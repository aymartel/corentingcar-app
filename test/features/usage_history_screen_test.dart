import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/models/models.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:coretingcar/features/usage_history/usage_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpHistory(
  WidgetTester tester, {
  List<UsageLog> usages = const [],
  List<UsageChange> changes = const [],
  bool failList = false,
  FakeUsageChangeService? changeService,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        usageServiceProvider.overrideWithValue(
          FakeUsageService(usageList: usages, failList: failList),
        ),
        usageChangeServiceProvider.overrideWithValue(
          changeService ?? FakeUsageChangeService(listResult: changes),
        ),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        currentUserProvider.overrideWithValue(user1),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const UsageHistoryScreen(),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('muestra los usos y los cambios pendientes con acciones por rol', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      usages: usageLogsSample(),
      changes: usageChangesSample(),
    );

    expect(find.text('PENDIENTES DE APROBACIÓN'), findsOneWidget);
    expect(find.text('TODOS LOS USOS'), findsOneWidget);
    // Cambio entrante (Dennis → Andy): aprobar/rechazar. Saliente (Andy): cancelar.
    expect(find.text('APROBAR'), findsOneWidget);
    expect(find.text('RECHAZAR'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    // Etiquetas PENDIENTE (chips de estado + tiles con cambio pendiente).
    expect(find.text('PENDIENTE'), findsWidgets);
  });

  testWidgets('aprobar un cambio entrante llama al servicio', (tester) async {
    final changes = FakeUsageChangeService(listResult: usageChangesSample());
    await _pumpHistory(
      tester,
      usages: usageLogsSample(),
      changeService: changes,
    );

    await tester.tap(find.text('APROBAR'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(changes.approveCalls, 1);
  });

  testWidgets('cancelar un cambio saliente llama al servicio', (tester) async {
    final changes = FakeUsageChangeService(listResult: usageChangesSample());
    await _pumpHistory(
      tester,
      usages: usageLogsSample(),
      changeService: changes,
    );

    await tester.tap(find.text('CANCELAR'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(changes.cancelCalls, 1);
  });

  testWidgets('eliminar un uso abre confirmación y propone el cambio', (
    tester,
  ) async {
    final changes = FakeUsageChangeService();
    await _pumpHistory(
      tester,
      usages: const [
        UsageLog(
          id: 7,
          userId: 1,
          date: '2026-06-02',
          startKm: 0,
          endKm: 40,
          totalKm: 40,
          type: EntryType.individual,
        ),
      ],
      changeService: changes,
    );

    await tester.tap(find.text('ELIMINAR'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar este uso?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(changes.proposeDeleteCalls, 1);
  });

  testWidgets('un uso con cambio pendiente deshabilita editar/eliminar', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      usages: const [
        UsageLog(
          id: 1,
          userId: 1,
          date: '2026-06-03',
          startKm: 0,
          endKm: 100,
          totalKm: 100,
          type: EntryType.individual,
        ),
      ],
      // Cambio pendiente sobre el uso 1.
      changes: [usageChangesSample().first],
    );

    expect(find.text('PENDIENTE'), findsWidgets);
    // Editar y eliminar quedan deshabilitados mientras hay un cambio pendiente.
    // TextButton.icon crea un subtipo de TextButton, por eso usamos bySubtype.
    final editBtn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('EDITAR'),
        matching: find.bySubtype<TextButton>(),
      ),
    );
    expect(editBtn.onPressed, isNull);
    final deleteBtn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('ELIMINAR'),
        matching: find.bySubtype<TextButton>(),
      ),
    );
    expect(deleteBtn.onPressed, isNull);
  });

  testWidgets('estado de error muestra el fallback y reintentar', (
    tester,
  ) async {
    await _pumpHistory(tester, failList: true);

    expect(
      find.text('No se pudo cargar el historial de usos.'),
      findsOneWidget,
    );
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
