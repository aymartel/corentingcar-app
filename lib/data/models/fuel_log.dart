import 'entry_type.dart';
import 'json_utils.dart';

/// Repostaje de gasolina (Fase F2). `POST /api/fuel`. Individual = lo paga
/// quien consume; compartido = 50/50.
class FuelLog {
  const FuelLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountEur,
    required this.type,
    this.createdAt,
  });

  final int id;
  final int userId;

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;
  final double amountEur;
  final EntryType type;
  final String? createdAt;

  factory FuelLog.fromJson(JsonMap json) => FuelLog(
    id: jInt(json['id']),
    userId: jInt(json['userId']),
    date: jStr(json['date']),
    amountEur: jDouble(json['amountEur']),
    type: EntryType.fromJson(jStr(json['type'])),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'userId': userId,
    'date': date,
    'amountEur': amountEur,
    'type': type.toJson(),
    'createdAt': createdAt,
  };
}
