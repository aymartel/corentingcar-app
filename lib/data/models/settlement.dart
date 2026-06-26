import 'json_utils.dart';

/// Pago directo entre los 2 usuarios (saldar cuentas), sin vincular a un gasto.
/// `POST /api/settlements`. Ajusta el saldo combinado: reduce lo que `fromUser`
/// debe a `toUser` (o lo invierte si paga de más).
class Settlement {
  const Settlement({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.date,
    required this.amountEur,
    this.note,
    this.createdAt,
  });

  final int id;
  final int fromUserId;
  final int toUserId;

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;
  final double amountEur;
  final String? note;
  final String? createdAt;

  factory Settlement.fromJson(JsonMap json) => Settlement(
    id: jInt(json['id']),
    fromUserId: jInt(json['fromUserId']),
    toUserId: jInt(json['toUserId']),
    date: jStr(json['date']),
    amountEur: jDouble(json['amountEur']),
    note: jStrOrNull(json['note']),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'date': date,
    'amountEur': amountEur,
    'note': note,
    'createdAt': createdAt,
  };
}
