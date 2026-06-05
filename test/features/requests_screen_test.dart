import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:coretingcar/features/requests/requests_controller.dart';
import 'package:coretingcar/features/requests/requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pumpRequests(
  WidgetTester tester,
  FakeRequestService requests,
) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        requestServiceProvider.overrideWithValue(requests),
        currentUserProvider.overrideWithValue(user1),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const RequestsScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('lista recibidas/enviadas/historial con acciones', (
    tester,
  ) async {
    await _pumpRequests(
      tester,
      FakeRequestService(listResult: requestsSample()),
    );

    expect(find.text('PENDIENTES · RECIBIDAS'), findsOneWidget);
    expect(find.text('ACEPTAR'), findsOneWidget);
    expect(find.text('RECHAZAR'), findsOneWidget);
    expect(find.text('PENDIENTES · ENVIADAS'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    expect(find.text('HISTORIAL'), findsOneWidget);
    expect(find.text('ACEPTADA'), findsOneWidget);
  });

  testWidgets('aceptar llama al servicio', (tester) async {
    final requests = FakeRequestService(listResult: requestsSample());
    await _pumpRequests(tester, requests);

    await tester.tap(find.text('ACEPTAR'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(requests.acceptCalls, 1);
  });

  test('pendingCountProvider cuenta las pendientes', () async {
    final container = ProviderContainer(
      overrides: [
        requestServiceProvider.overrideWithValue(
          FakeRequestService(
            pendingResult: requestsSample()
                .where((r) => r.recipientId == 1)
                .toList(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(pendingRequestsProvider, (_, _) {});
    await container.read(pendingRequestsProvider.future);

    expect(container.read(pendingCountProvider), 1);
  });
}
