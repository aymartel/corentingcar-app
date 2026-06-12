import 'entry_type.dart';
import 'json_utils.dart';

/// Parte del reparto de un repostaje para una persona (snapshot persistido).
class FuelSplitPerUser {
  const FuelSplitPerUser({
    required this.userId,
    required this.km,
    required this.shareEur,
  });

  final int userId;
  final double km;
  final double shareEur;

  factory FuelSplitPerUser.fromJson(JsonMap json) => FuelSplitPerUser(
    userId: jInt(json['userId']),
    km: jDouble(json['km']),
    shareEur: jDouble(json['shareEur']),
  );

  JsonMap toJson() => {'userId': userId, 'km': km, 'shareEur': shareEur};
}

/// Reparto por km de un repostaje, tal y como se persistió. `method` es `'km'`
/// (proporcional a km) o `'fallback_5050'` (sin km en el periodo → 50/50).
class FuelSplit {
  const FuelSplit({
    required this.method,
    required this.payerShareEur,
    required this.perUser,
  });

  final String method;
  final double payerShareEur;
  final List<FuelSplitPerUser> perUser;

  bool get isFallback => method == 'fallback_5050';

  factory FuelSplit.fromJson(JsonMap json) => FuelSplit(
    method: jStr(json['method']),
    payerShareEur: jDouble(json['payerShareEur']),
    perUser: asMapList(json['perUser']).map(FuelSplitPerUser.fromJson).toList(),
  );

  JsonMap toJson() => {
    'method': method,
    'payerShareEur': payerShareEur,
    'perUser': perUser.map((p) => p.toJson()).toList(),
  };
}

/// Repostaje de gasolina (Fase F2). `POST /api/fuel`. Siempre compartido: el
/// importe se reparte por los km de cada persona desde el último repostaje
/// ([split]; `null` en repostajes antiguos previos a la feature).
class FuelLog {
  const FuelLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountEur,
    required this.type,
    this.odometerKm,
    this.split,
    this.createdAt,
  });

  final int id;
  final int userId;

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;
  final double amountEur;
  final EntryType type;

  /// Km del cuadro al repostar; `null` en repostajes antiguos.
  final int? odometerKm;

  /// Reparto por km persistido; `null` en repostajes antiguos (reparto 50/50 por `type`).
  final FuelSplit? split;
  final String? createdAt;

  factory FuelLog.fromJson(JsonMap json) => FuelLog(
    id: jInt(json['id']),
    userId: jInt(json['userId']),
    date: jStr(json['date']),
    amountEur: jDouble(json['amountEur']),
    type: EntryType.fromJson(jStr(json['type'])),
    odometerKm: jIntOrNull(json['odometerKm']),
    split: json['split'] == null ? null : FuelSplit.fromJson(asMap(json['split'])),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'userId': userId,
    'date': date,
    'amountEur': amountEur,
    'type': type.toJson(),
    'odometerKm': odometerKm,
    'split': split?.toJson(),
    'createdAt': createdAt,
  };
}
