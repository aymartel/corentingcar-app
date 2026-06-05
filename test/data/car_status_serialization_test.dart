import 'package:coretingcar/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serialización de `CarStatus` (Fase F12). El backend manda `since` en **UTC**;
/// el modelo lo guarda en **hora local**. `parking` usa el perfil (`user1`/`user2`).
void main() {
  test('libre con parqueo, nota y since (UTC → local)', () {
    final status = CarStatus.fromJson({
      'status': 'free',
      'user': {'id': 1, 'name': 'Andy', 'profile': 'user1', 'color': '#9CC93B'},
      'parking': 'user2',
      'parkingUser': {
        'id': 2,
        'name': 'Dennis',
        'profile': 'user2',
        'color': '#FF8A3D',
      },
      'note': 'Plaza 12',
      'since': '2026-06-04T12:30:00.000Z',
    });

    expect(status.availability, CarAvailability.free);
    expect(status.isFree, isTrue);
    expect(status.parking, ParkingSpot.user2);
    expect(status.parkingUser?.name, 'Dennis');
    expect(status.note, 'Plaza 12');
    expect(status.since, isNotNull);
    expect(status.since!.isUtc, isFalse); // convertido a hora local
  });

  test('ocupado por una persona', () {
    final status = CarStatus.fromJson({
      'status': 'taken',
      'user': {'id': 2, 'name': 'Dennis', 'profile': 'user2', 'color': '#FF8A3D'},
      'parking': null,
      'parkingUser': null,
      'note': null,
      'since': '2026-06-04T08:00:00.000Z',
    });

    expect(status.isTaken, isTrue);
    expect(status.user?.name, 'Dennis');
    expect(status.parking, isNull);
  });

  test('parqueo "otro" → sin parkingUser, la nota es la ubicación', () {
    final status = CarStatus.fromJson({
      'status': 'free',
      'user': {'id': 1, 'name': 'Andy', 'profile': 'user1', 'color': '#9CC93B'},
      'parking': 'other',
      'parkingUser': null,
      'note': 'Garaje del trabajo',
      'since': '2026-06-05T13:00:00.000Z',
    });

    expect(status.isFree, isTrue);
    expect(status.parking, ParkingSpot.other);
    expect(status.parkingUser, isNull);
    expect(status.note, 'Garaje del trabajo');
  });

  test('sin eventos (nunca registrado) = libre', () {
    final status = CarStatus.fromJson({
      'status': 'free',
      'user': null,
      'parking': null,
      'parkingUser': null,
      'note': null,
      'since': null,
    });

    expect(status.isFree, isTrue);
    expect(status.user, isNull);
    expect(status.since, isNull);
  });
}
