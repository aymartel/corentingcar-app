// Smoke test del arranque (Fase F3): el AuthGate enruta a login o al shell
// según la sesión, conservando el tema oscuro de marca.

import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/shell/navigation_controller.dart';
import 'package:coretingcar/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/fakes.dart';

/// Deja que la restauración de sesión (async) termine y el AuthGate cambie de
/// pantalla, sin usar `pumpAndSettle` (el splash anima en bucle).
Future<void> _boot(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('con sesión → shell de 4 pestañas y navega', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(
            FakeTokenStore(token: 't', user: andy),
          ),
          authServiceProvider.overrideWithValue(FakeAuthService(meUser: andy)),
          priorityServiceProvider.overrideWithValue(
            FakePriorityService(todayResult: priorityFor(andy)),
          ),
          usageServiceProvider.overrideWithValue(
            FakeUsageService(mileageResult: mileageSample()),
          ),
          expensesServiceProvider.overrideWithValue(
            FakeExpensesService(summaryResult: expensesSample()),
          ),
          requestServiceProvider.overrideWithValue(FakeRequestService()),
        ],
        child: const CoRetingCarApp(),
      ),
    );
    await _boot(tester);

    // Tema oscuro de marca aplicado.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, AppColors.bg);

    // Las 4 pestañas en español + pestaña inicial HOY con contenido real.
    expect(find.text('CALENDARIO'), findsOneWidget);
    expect(find.text('KILÓMETROS'), findsOneWidget);
    expect(find.text('GASTOS'), findsOneWidget);
    expect(find.text('HOY TIENE PRIORIDAD'), findsOneWidget);

    // Tocar GASTOS actualiza el índice del shell a la pestaña 3.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(navigationControllerProvider), 0);
    await tester.tap(find.text('GASTOS'));
    await tester.pump();
    expect(container.read(navigationControllerProvider), 3);
  });

  testWidgets('sin sesión → login con perfiles y PIN', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(FakeTokenStore()),
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const CoRetingCarApp(),
      ),
    );
    await _boot(tester);

    expect(find.text('ELIGE TU PERFIL'), findsOneWidget);
    expect(find.text('Andy'), findsWidgets);
    expect(find.text('Dennis'), findsWidgets);
    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
