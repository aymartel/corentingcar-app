import 'fuel_log.dart';
import 'json_utils.dart';
import 'other_expense_log.dart';
import 'settlement.dart';
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

/// Otro gasto con la persona que pagó (entrada del historial de otros gastos).
class OtherExpenseEntry {
  const OtherExpenseEntry({required this.log, required this.user});

  final OtherExpenseLog log;
  final User user;

  factory OtherExpenseEntry.fromJson(JsonMap json) => OtherExpenseEntry(
    log: OtherExpenseLog.fromJson(json),
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

/// Pago directo con quién pagó y quién recibió (entrada del historial de pagos).
class SettlementEntry {
  const SettlementEntry({
    required this.log,
    required this.fromUser,
    required this.toUser,
  });

  final Settlement log;
  final User fromUser;
  final User toUser;

  factory SettlementEntry.fromJson(JsonMap json) => SettlementEntry(
    log: Settlement.fromJson(json),
    fromUser: User.fromJson(asMap(json['fromUser'])),
    toUser: User.fromJson(asMap(json['toUser'])),
  );

  JsonMap toJson() => {
    ...log.toJson(),
    'fromUser': fromUser.toJson(),
    'toUser': toUser.toJson(),
  };
}

/// Total de gasto pagado por una persona (gasolina u otros).
class ExpenseTotal {
  const ExpenseTotal({required this.user, required this.totalEur});

  final User user;
  final double totalEur;

  factory ExpenseTotal.fromJson(JsonMap json) => ExpenseTotal(
    user: User.fromJson(asMap(json['user'])),
    totalEur: jDouble(json['totalEur']),
  );

  JsonMap toJson() => {'user': user.toJson(), 'totalEur': totalEur};
}

/// Saldo entre las dos personas: quién debe a quién. Combina gasolina + otros.
class ExpenseBalance {
  const ExpenseBalance({
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

  factory ExpenseBalance.fromJson(JsonMap json) => ExpenseBalance(
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

/// Sección de gasolina del resumen de gastos. `balance` es el saldo combinado
/// (gasolina + otros), mantenido aquí como alias para compatibilidad.
class FuelSection {
  const FuelSection({
    required this.list,
    required this.totalPerUser,
    required this.balance,
  });

  final List<FuelEntry> list;
  final List<ExpenseTotal> totalPerUser;
  final ExpenseBalance balance;

  factory FuelSection.fromJson(JsonMap json) => FuelSection(
    list: asMapList(json['list']).map(FuelEntry.fromJson).toList(),
    totalPerUser: asMapList(
      json['totalPerUser'],
    ).map(ExpenseTotal.fromJson).toList(),
    balance: ExpenseBalance.fromJson(asMap(json['balance'])),
  );

  JsonMap toJson() => {
    'list': list.map((e) => e.toJson()).toList(),
    'totalPerUser': totalPerUser.map((t) => t.toJson()).toList(),
    'balance': balance.toJson(),
  };
}

/// Sección de otros gastos del resumen.
class OtherSection {
  const OtherSection({required this.list, required this.totalPerUser});

  final List<OtherExpenseEntry> list;
  final List<ExpenseTotal> totalPerUser;

  /// Sección vacía (backend antiguo sin la clave `other`).
  factory OtherSection.empty() =>
      const OtherSection(list: [], totalPerUser: []);

  factory OtherSection.fromJson(JsonMap json) => OtherSection(
    list: asMapList(json['list']).map(OtherExpenseEntry.fromJson).toList(),
    totalPerUser: asMapList(
      json['totalPerUser'],
    ).map(ExpenseTotal.fromJson).toList(),
  );

  JsonMap toJson() => {
    'list': list.map((e) => e.toJson()).toList(),
    'totalPerUser': totalPerUser.map((t) => t.toJson()).toList(),
  };
}

/// Sección de pagos directos (saldar cuentas) entre los 2 usuarios.
class SettlementSection {
  const SettlementSection({required this.list});

  final List<SettlementEntry> list;

  /// Sección vacía (backend antiguo sin la clave `settlements`).
  factory SettlementSection.empty() => const SettlementSection(list: []);

  factory SettlementSection.fromJson(JsonMap json) => SettlementSection(
    list: asMapList(json['list']).map(SettlementEntry.fromJson).toList(),
  );

  JsonMap toJson() => {'list': list.map((e) => e.toJson()).toList()};
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

/// Resumen de gastos (Fase F7). `GET /api/expenses`. `balance` es el saldo
/// combinado (gasolina + otros). Tolerante a backend antiguo: si falta `other`
/// la sección queda vacía y si falta `balance` cae al alias `fuel.balance`.
class ExpensesSummary {
  const ExpensesSummary({
    required this.fuel,
    required this.other,
    required this.settlements,
    required this.balance,
    required this.wash,
  });

  final FuelSection fuel;
  final OtherSection other;
  final SettlementSection settlements;
  final ExpenseBalance balance;
  final WashSection wash;

  factory ExpensesSummary.fromJson(JsonMap json) {
    final fuel = FuelSection.fromJson(asMap(json['fuel']));
    return ExpensesSummary(
      fuel: fuel,
      other: json['other'] == null
          ? OtherSection.empty()
          : OtherSection.fromJson(asMap(json['other'])),
      settlements: json['settlements'] == null
          ? SettlementSection.empty()
          : SettlementSection.fromJson(asMap(json['settlements'])),
      balance: json['balance'] == null
          ? fuel.balance
          : ExpenseBalance.fromJson(asMap(json['balance'])),
      wash: WashSection.fromJson(asMap(json['wash'])),
    );
  }

  JsonMap toJson() => {
    'fuel': fuel.toJson(),
    'other': other.toJson(),
    'settlements': settlements.toJson(),
    'balance': balance.toJson(),
    'wash': wash.toJson(),
  };
}
