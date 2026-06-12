import 'package:coretingcar/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de serialización (Fase F2): `fromJson`/`toJson` redondean sin pérdida
/// y los enums mapean exactamente los valores del contrato.
void main() {
  group('Rules', () {
    test('deserializa GET /api/rules', () {
      final rules = Rules.fromJson({
        'monthlyFeeEur': 355.0,
        'feeSplitPct': 50.0,
        'feePerPerson': 177.5,
        'annualKmTotal': 15000,
        'annualKmPerPerson': 7500,
        'kmWindow': 'natural',
        'sharedKmRounding': 1,
        'anchorDate': '2026-01-01',
        'anchorUserId': 1,
        'firstWashUserId': 2,
        'timezone': 'Europe/Madrid',
        'updatedAt': '2026-06-04 10:00:00',
      });

      expect(rules.monthlyFeeEur, 355.0);
      expect(rules.feePerPerson, 177.5);
      expect(rules.annualKmPerPerson, 7500);
      expect(rules.timezone, 'Europe/Madrid');

      final round = Rules.fromJson(rules.toJson());
      expect(round.feePerPerson, rules.feePerPerson);
      expect(round.anchorDate, rules.anchorDate);
    });
  });

  group('User', () {
    test('round-trip', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Andy',
        'profile': 'user1',
        'color': '#9CC93B',
      });
      expect(user.profile, 'user1');
      expect(User.fromJson(user.toJson()).color, '#9CC93B');
    });
  });

  group('Enums', () {
    test('RequestStatus mapea los 4 estados', () {
      expect(RequestStatus.fromJson('pending'), RequestStatus.pending);
      expect(RequestStatus.fromJson('accepted'), RequestStatus.accepted);
      expect(RequestStatus.fromJson('rejected'), RequestStatus.rejected);
      expect(RequestStatus.fromJson('cancelled'), RequestStatus.cancelled);
      expect(RequestStatus.accepted.toJson(), 'accepted');
      expect(() => RequestStatus.fromJson('unknown'), throwsArgumentError);
    });

    test('EntryType mapea individual/shared', () {
      expect(EntryType.fromJson('individual'), EntryType.individual);
      expect(EntryType.fromJson('shared'), EntryType.shared);
      expect(EntryType.shared.toJson(), 'shared');
      expect(EntryType.shared.isShared, isTrue);
    });
  });

  group('UsageLog', () {
    test('round-trip con enum type', () {
      final log = UsageLog.fromJson({
        'id': 10,
        'userId': 1,
        'date': '2026-06-04',
        'startKm': 12000,
        'endKm': 12150,
        'totalKm': 150,
        'type': 'shared',
        'createdAt': '2026-06-04 11:00:00',
      });
      expect(log.totalKm, 150);
      expect(log.type, EntryType.shared);
      expect(UsageLog.fromJson(log.toJson()).type, EntryType.shared);
    });
  });

  group('MileageSummary', () {
    test('parsea perUser (user anidado) y agregados', () {
      final summary = MileageSummary.fromJson({
        'kmWindow': 'natural',
        'annualKmTotal': 15000,
        'annualKmPerPerson': 7500,
        'sharedKm': 120,
        'sharedKmPerPerson': 60,
        'perUser': [
          {
            'user': {
              'id': 1,
              'name': 'Andy',
              'profile': 'user1',
              'color': '#9CC93B',
            },
            'individualKm': 6240,
            'usedKm': 6240,
            'remainingKm': 1260,
            'exceeded': false,
            'excessKm': 0,
          },
          {
            'user': {
              'id': 2,
              'name': 'Dennis',
              'profile': 'user2',
              'color': '#FF8A3D',
            },
            'individualKm': 8430,
            'usedKm': 8430,
            'remainingKm': -930,
            'exceeded': true,
            'excessKm': 930,
          },
        ],
      });

      expect(summary.people, hasLength(2));
      expect(summary.people[0].user.name, 'Andy');
      expect(summary.people[1].exceeded, isTrue);
      expect(summary.people[1].excessKm, 930);
      expect(summary.sharedKmPerPerson, 60);
      expect(MileageSummary.fromJson(summary.toJson()).annualKmTotal, 15000);
    });
  });

  group('FuelLog / WashLog', () {
    test('fuel round-trip', () {
      final fuel = FuelLog.fromJson({
        'id': 3,
        'userId': 2,
        'date': '2026-06-01',
        'amountEur': 50.0,
        'type': 'individual',
        'createdAt': null,
      });
      expect(fuel.amountEur, 50.0);
      expect(FuelLog.fromJson(fuel.toJson()).type, EntryType.individual);
    });

    test('wash con costEur nulo', () {
      final wash = WashLog.fromJson({
        'id': 4,
        'userId': 1,
        'date': '2026-05-20',
        'costEur': null,
        'createdAt': null,
      });
      expect(wash.costEur, isNull);
      expect(WashLog.fromJson(wash.toJson()).date, '2026-05-20');
    });
  });

  group('UseRequest', () {
    test('round-trip con status', () {
      final req = UseRequest.fromJson({
        'id': 7,
        'requesterId': 1,
        'recipientId': 2,
        'useDate': '2026-06-10',
        'status': 'pending',
        'message': '¿Me lo dejas?',
        'createdAt': '2026-06-04 09:00:00',
        'resolvedAt': null,
      });
      expect(req.status, RequestStatus.pending);
      expect(req.status.isPending, isTrue);
      expect(UseRequest.fromJson(req.toJson()).useDate, '2026-06-10');
    });
  });

  group('DailyPriority / CalendarDay', () {
    const userJson = {
      'id': 1,
      'name': 'Andy',
      'profile': 'user1',
      'color': '#9CC93B',
    };

    test('priority today', () {
      final p = DailyPriority.fromJson({
        'date': '2026-06-04',
        'priorityUser': userJson,
        'isMyDay': true,
        'conflictPhrase': 'Hoy decide Andy.',
      });
      expect(p.priorityUser.profile, 'user1');
      expect(p.isMyDay, isTrue);
      expect(DailyPriority.fromJson(p.toJson()).date, '2026-06-04');
    });

    test('calendar day con handover', () {
      final day = CalendarDay.fromJson({
        'date': '2026-06-05',
        'priorityUser': userJson,
        'handover': {'origin': 'request_accepted', 'requestId': 7},
      });
      expect(day.isHandover, isTrue);
      expect(day.origin, 'request_accepted');

      final normal = CalendarDay.fromJson({
        'date': '2026-06-06',
        'priorityUser': userJson,
        'handover': null,
      });
      expect(normal.isHandover, isFalse);
    });
  });

  group('ExpensesSummary', () {
    const user1Json = {
      'id': 1,
      'name': 'Andy',
      'profile': 'user1',
      'color': '#9CC93B',
    };
    const user2Json = {
      'id': 2,
      'name': 'Dennis',
      'profile': 'user2',
      'color': '#FF8A3D',
    };

    test('parsea fuel, other, balance combinado y wash', () {
      final exp = ExpensesSummary.fromJson({
        'fuel': {
          'list': [
            {
              'id': 1,
              'userId': 2,
              'date': '2026-06-01',
              'amountEur': 25.0,
              'type': 'shared',
              'createdAt': null,
              'user': user2Json,
            },
          ],
          'totalPerUser': [
            {'user': user1Json, 'totalEur': 0},
            {'user': user2Json, 'totalEur': 25.0},
          ],
          // Alias del combinado (mismo valor que el top-level).
          'balance': {
            'settled': false,
            'amountEur': 8.5,
            'fromUser': user1Json,
            'toUser': user2Json,
          },
        },
        'other': {
          'list': [
            {
              'id': 3,
              'userId': 1,
              'date': '2026-06-05',
              'amountEur': 8.0,
              'type': 'shared',
              'description': 'Peaje AP-7',
              'createdAt': null,
              'user': user1Json,
            },
          ],
          'totalPerUser': [
            {'user': user1Json, 'totalEur': 8.0},
            {'user': user2Json, 'totalEur': 0},
          ],
        },
        'balance': {
          'settled': false,
          'amountEur': 8.5,
          'fromUser': user1Json,
          'toUser': user2Json,
        },
        'wash': {
          'last': {
            'id': 9,
            'userId': 1,
            'date': '2026-05-20',
            'costEur': 15.0,
            'createdAt': null,
            'user': user1Json,
          },
          'nextWashUser': user2Json,
          'history': const [],
        },
      });

      // Saldo combinado top-level + alias en fuel.balance.
      expect(exp.balance.amountEur, 8.5);
      expect(exp.balance.fromUser?.name, 'Andy');
      expect(exp.fuel.balance.amountEur, 8.5);
      // Sección de gasolina.
      expect(exp.fuel.list, hasLength(1));
      expect(exp.fuel.list.first.user.name, 'Dennis');
      expect(exp.fuel.list.first.log.type, EntryType.shared);
      // Sección de otros gastos.
      expect(exp.other.list, hasLength(1));
      expect(exp.other.list.first.log.description, 'Peaje AP-7');
      expect(exp.other.list.first.user.name, 'Andy');
      expect(exp.other.totalPerUser.first.totalEur, 8.0);
      // Lavado.
      expect(exp.wash.nextWashUser.name, 'Dennis');
      expect(exp.wash.last?.log.costEur, 15.0);
      expect(exp.wash.history, isEmpty);

      // Round-trip completo.
      expect(ExpensesSummary.fromJson(exp.toJson()).balance.amountEur, 8.5);
    });

    test('compatibilidad: backend antiguo sin "other" ni "balance"', () {
      final exp = ExpensesSummary.fromJson({
        'fuel': {
          'list': const [],
          'totalPerUser': const [],
          'balance': {
            'settled': false,
            'amountEur': 12.5,
            'fromUser': user1Json,
            'toUser': user2Json,
          },
        },
        'wash': {'last': null, 'nextWashUser': user2Json, 'history': const []},
      });

      // No lanza: sección de otros vacía y balance cae al alias de fuel.
      expect(exp.other.list, isEmpty);
      expect(exp.other.totalPerUser, isEmpty);
      expect(exp.balance.amountEur, exp.fuel.balance.amountEur);
      expect(exp.balance.amountEur, 12.5);
    });
  });
}
