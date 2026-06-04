import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:coretingcar/features/rules/rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpRules(
  WidgetTester tester, {
  required FakeTokenStore tokenStore,
}) async {
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rulesServiceProvider.overrideWithValue(
          FakeRulesService(result: rulesSample()),
        ),
        currentUserProvider.overrideWithValue(andy),
        tokenStoreProvider.overrideWithValue(tokenStore),
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const RulesScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('muestra reglas, perfil, versión y entorno', (tester) async {
    await _pumpRules(tester, tokenStore: FakeTokenStore());

    // Reparto económico y km desde GET /api/rules.
    expect(find.textContaining('355,00'), findsOneWidget);
    expect(find.textContaining('177,50'), findsOneWidget);
    expect(find.textContaining('16.000 km'), findsOneWidget);
    expect(find.textContaining('8.000 km'), findsOneWidget);
    // Reglas fijas.
    expect(find.textContaining('quien consume'), findsOneWidget);
    expect(find.text('Alterna: uno cada uno'), findsOneWidget);

    // Ajustes: perfil activo, versión y base URL.
    expect(find.text('PERFIL ACTIVO'), findsOneWidget);
    expect(find.text('Andy'), findsWidgets);
    expect(find.textContaining('1.0.0'), findsOneWidget);
    expect(find.textContaining('localhost'), findsOneWidget);
    expect(find.text('CERRAR SESIÓN'), findsOneWidget);
  });

  testWidgets('cerrar sesión limpia el token persistido', (tester) async {
    final store = FakeTokenStore(token: 't', user: andy);
    await _pumpRules(tester, tokenStore: store);

    expect(await store.readToken(), 't');

    await tester.tap(find.text('CERRAR SESIÓN'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(await store.readToken(), isNull);
  });
}
