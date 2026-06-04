import 'fuel_log.dart';
import 'json_utils.dart';
import 'user.dart';
import 'wash_log.dart';

/// Repostaje con la persona que pagó (entrada del historial de gasolina).
class FuelEntry {
  const FuelEntry({required this.log, required this.user});

  final FuelLog log;
  final User user;

  factory FuelEntry.fromJson(JsonMap json) => FuelEntry(
    log: FuelLog.fromJson(json),
    user: User.fromJson(asMap(json['user'])),
  );

  JsonMap toJson() => {...log.toJson(), 'user': user.toJson()};
}

/// Lavado con la persona que lo hizo (entrada del historial de lavado).
class WashEntry {
  const WashEntry({required this.log, required this.user});

  final WashLog log;
  final User user;

  factory WashEntry.fromJson(JsonMap json) => WashEntry(
    log: WashLog.fromJson(json),
    user: User.fromJson(asMap(json['user'])),
  );

  JsonMap toJson() => {...log.toJson(), 'user': user.toJson()};
}

/// Total de gasolina pagado por una persona.
class FuelTotal {
  const FuelTotal({required this.user, required this.totalEur});

  final User user;
  final double totalEur;

  factory FuelTotal.fromJson(JsonMap json) => FuelTotal(
    user: User.fromJson(asMap(json['user'])),
    totalEur: jDouble(json['totalEur']),
  );

  JsonMap toJson() => {'user': user.toJson(), 'totalEur': totalEur};
}

/// Saldo de gasolina entre las dos personas: quién debe a quién.
class FuelBalance {
  const FuelBalance({
    required this.settled,
    required this.amountEur,
    this.fromUser,
    this.toUser,
  });

  /// `true` si están en paz (`amountEur == 0`).
  final bool settled;
  final double amountEur;

  /// Quién debe y a quién (nulos si `settled`).
  final User? fromUser;
  final User? toUser;

  factory FuelBalance.fromJson(JsonMap json) => FuelBalance(
    settled: jBool(json['settled']),
    amountEur: jDouble(json['amountEur']),
    fromUser: json['fromUser'] == null
        ? null
        : User.fromJson(asMap(json['fromUser'])),
    toUser: json['toUser'] == null
        ? null
        : User.fromJson(asMap(json['toUser'])),
  );

  JsonMap toJson() => {
    'settled': settled,
    'amountEur': amountEur,
    'fromUser': fromUser?.toJson(),
    'toUser': toUser?.toJson(),
  };
}

/// Sección de gasolina del resumen de gastos.
class FuelSection {
  const FuelSection({
    required this.list,
    required this.totalPerUser,
    required this.balance,
  });

  final List<FuelEntry> list;
  final List<FuelTotal> totalPerUser;
  final FuelBalance balance;

  factory FuelSection.fromJson(JsonMap json) => FuelSection(
    list: asMapList(json['list']).map(FuelEntry.fromJson).toList(),
    totalPerUser: asMapList(
      json['totalPerUser'],
    ).map(FuelTotal.fromJson).toList(),
    balance: FuelBalance.fromJson(asMap(json['balance'])),
  );

  JsonMap toJson() => {
    'list': list.map((e) => e.toJson()).toList(),
    'totalPerUser': totalPerUser.map((t) => t.toJson()).toList(),
    'balance': balance.toJson(),
  };
}

/// Sección de lavado: último, a quién le toca el próximo (alternancia) e historial.
class WashSection {
  const WashSection({
    required this.last,
    required this.nextWashUser,
    required this.history,
  });

  final WashEntry? last;
  final User nextWashUser;
  final List<WashEntry> history;

  factory WashSection.fromJson(JsonMap json) => WashSection(
    last: json['last'] == null ? null : WashEntry.fromJson(asMap(json['last'])),
    nextWashUser: User.fromJson(asMap(json['nextWashUser'])),
    history: asMapList(json['history']).map(WashEntry.fromJson).toList(),
  );

  JsonMap toJson() => {
    'last': last?.toJson(),
    'nextWashUser': nextWashUser.toJson(),
    'history': history.map((e) => e.toJson()).toList(),
  };
}

/// Resumen de gastos (Fase F7). `GET /api/expenses`.
class ExpensesSummary {
  const ExpensesSummary({required this.fuel, required this.wash});

  final FuelSection fuel;
  final WashSection wash;

  factory ExpensesSummary.fromJson(JsonMap json) => ExpensesSummary(
    fuel: FuelSection.fromJson(asMap(json['fuel'])),
    wash: WashSection.fromJson(asMap(json['wash'])),
  );

  JsonMap toJson() => {'fuel': fuel.toJson(), 'wash': wash.toJson()};
}
