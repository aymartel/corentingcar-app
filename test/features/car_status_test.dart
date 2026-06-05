import 'package:coretingcar/common/theme/theme.dart';
import 'package:coretingcar/data/models/models.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/car_status/car_status_card.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fakes.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeCarStatusService car,
  FakeUsageService? usage,
  User? me,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        carStatusServiceProvider.overrideWithValue(car),
        usageServiceProvider.overrideWithValue(usage ?? FakeUsageService()),
        if (me != null) currentUserProvider.overrideWithValue(me),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: CarStatusCard()),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('libre → "Tengo el coche" lo marca tuyo', (tester) async {
    final car = FakeCarStatusService(); // empieza libre
    await _pump(tester, car: car, me: user1);

    expect(find.text('Coche libre'), findsOneWidget);
    expect(find.text('Tengo el coche'), findsOneWidget);

    await tester.tap(find.text('Tengo el coche'));
    await _settle(tester);

    expect(car.setCalls, 1);
    expect(car.lastStatus, CarAvailability.taken);
    expect(find.text('Lo tienes tú'), findsOneWidget);
    expect(find.text('Lo dejo libre'), findsOneWidget);
  });

  testWidgets('lo tienes tú → "Lo dejo libre" con parqueo lo libera', (
    tester,
  ) async {
    final car = FakeCarStatusService(
      status: CarStatus(
        availability: CarAvailability.taken,
        user: user1,
        since: DateTime(2026, 6, 4, 9),
      ),
    );
    await _pump(tester, car: car, me: user1);

    expect(find.text('Lo tienes tú'), findsOneWidget);

    await tester.tap(find.text('Lo dejo libre'));
    await tester.pumpAndSettle();
    expect(find.text('DEJAR LIBRE'), findsOneWidget);

    // Elegir parqueo (obligatorio) y confirmar sin km.
    await tester.tap(find.text('Casa de Dennis'));
    await tester.pump();
    await tester.tap(find.text('DEJAR LIBRE'));
    await tester.pumpAndSettle();

    expect(car.lastStatus, CarAvailability.free);
    expect(car.lastParking, ParkingSpot.user2);
    expect(find.text('Coche libre'), findsOneWidget);
    expect(find.text('Aparcado en casa de Dennis'), findsOneWidget);
  });

  testWidgets('parqueo "Otro" exige descripción y libera con la ubicación', (
    tester,
  ) async {
    final car = FakeCarStatusService(
      status: CarStatus(
        availability: CarAvailability.taken,
        user: user1,
        since: DateTime(2026, 6, 5, 9),
      ),
    );
    await _pump(tester, car: car, me: user1);

    await tester.tap(find.text('Lo dejo libre'));
    await tester.pumpAndSettle();

    // "Otro" sin descripción → error, no libera.
    await tester.tap(find.text('Otro'));
    await tester.pump();
    await tester.tap(find.text('DEJAR LIBRE'));
    await tester.pump();
    expect(find.text('Indica dónde lo dejas (descripción).'), findsOneWidget);
    expect(car.lastStatus, isNull);

    // Con descripción → libera con parking=other + nota.
    await tester.enterText(find.byType(TextField).last, 'Garaje del trabajo');
    await tester.pump();
    await tester.tap(find.text('DEJAR LIBRE'));
    await tester.pumpAndSettle();

    expect(car.lastStatus, CarAvailability.free);
    expect(car.lastParking, ParkingSpot.other);
    expect(car.lastNote, 'Garaje del trabajo');
    expect(find.text('Coche libre'), findsOneWidget);
    expect(find.text('Aparcado en: Garaje del trabajo'), findsOneWidget);
  });

  testWidgets('lo tiene el otro → botón "Tengo el coche"', (tester) async {
    final car = FakeCarStatusService(
      status: CarStatus(
        availability: CarAvailability.taken,
        user: user2,
        since: DateTime(2026, 6, 4, 9),
      ),
    );
    await _pump(tester, car: car, me: user1);

    expect(find.text('Lo tiene Dennis'), findsOneWidget);
    expect(find.text('Tengo el coche'), findsOneWidget);
  });
}
