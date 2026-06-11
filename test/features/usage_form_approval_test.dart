import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/models/models.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:coretingcar/features/expenses/forms/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _openForm(
  WidgetTester tester, {
  required FakeUsageService usage,
  required FakeUsageChangeService changes,
  UsageLog? edit,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        usageServiceProvider.overrideWithValue(usage),
        usageChangeServiceProvider.overrideWithValue(changes),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        currentUserProvider.overrideWithValue(user1),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => openUsageForm(context, edit: edit),
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

  testWidgets('edición: prerellena y propone una actualización', (tester) async {
    final usage = FakeUsageService();
    final changes = FakeUsageChangeService();
    await _openForm(
      tester,
      usage: usage,
      changes: changes,
      edit: const UsageLog(
        id: 12,
        userId: 1,
        date: '2026-05-02',
        startKm: 200,
        endKm: 250,
        totalKm: 50,
        type: EntryType.individual,
      ),
    );

    // Campos prerellenados desde el uso a editar.
    expect(find.text('200'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);

    await tester.tap(find.text('ENVIAR PARA APROBAR'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(changes.proposeUpdateCalls, 1);
    expect(usage.createCalls, 0);
  });

  testWidgets('alta desincronizada: confirma y propone un alta', (tester) async {
    final usage = FakeUsageService(
      usageList: const [
        UsageLog(
          id: 1,
          userId: 1,
          date: '2026-06-03',
          startKm: 0,
          endKm: 120,
          totalKm: 120,
          type: EntryType.individual,
        ),
      ],
    );
    final changes = FakeUsageChangeService();
    await _openForm(tester, usage: usage, changes: changes);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '50'); // inicial < odómetro (120)
    await tester.enterText(fields.at(1), '80');
    await tester.tap(find.text('GUARDAR'));
    // No pumpAndSettle: el botón muestra un spinner que nunca "asienta".
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Diálogo de aprobación.
    expect(find.text('Necesita aprobación'), findsOneWidget);
    await tester.tap(find.text('ENVIAR PARA APROBAR'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(changes.proposeCreateCalls, 1);
    expect(usage.createCalls, 0);
  });

  testWidgets('alta en sincronía: registro directo (sin diálogo)', (
    tester,
  ) async {
    final usage = FakeUsageService(
      usageList: const [
        UsageLog(
          id: 1,
          userId: 1,
          date: '2026-06-03',
          startKm: 0,
          endKm: 120,
          totalKm: 120,
          type: EntryType.individual,
        ),
      ],
    );
    final changes = FakeUsageChangeService();
    await _openForm(tester, usage: usage, changes: changes);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '120'); // en sincronía con el odómetro
    await tester.enterText(fields.at(1), '150');
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(usage.createCalls, 1);
    expect(changes.proposeCreateCalls, 0);
    expect(find.text('Necesita aprobación'), findsNothing);
  });

  testWidgets('carrera: ODOMETER_INCONSISTENT del alta directa cae al diálogo', (
    tester,
  ) async {
    final usage = FakeUsageService(
      // Lista vacía → sin odómetro conocido; el alta directa la rechaza el backend.
      createError: const ApiException(
        'ODOMETER_INCONSISTENT',
        'startKm es menor que el último odómetro.',
        statusCode: 400,
      ),
    );
    final changes = FakeUsageChangeService();
    await _openForm(tester, usage: usage, changes: changes);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '50');
    await tester.enterText(fields.at(1), '80');
    await tester.tap(find.text('GUARDAR'));
    // No pumpAndSettle: el botón muestra un spinner que nunca "asienta".
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Necesita aprobación'), findsOneWidget);
    await tester.tap(find.text('ENVIAR PARA APROBAR'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(usage.createCalls, 1); // se intentó el directo
    expect(changes.proposeCreateCalls, 1); // y cayó al flujo de aprobación
  });
}
