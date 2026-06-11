import 'entry_type.dart';
import 'json_utils.dart';

/// Otro gasto (peaje, líquido, multa, etc.). `POST /api/other-expenses`.
/// Individual = lo paga quien lo registra; compartido = 50/50. Lleva una
/// descripción obligatoria que lo distingue de gasolina/lavado.
class OtherExpenseLog {
  const OtherExpenseLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountEur,
    required this.type,
    required this.description,
    this.createdAt,
  });

  final int id;
  final int userId;

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;
  final double amountEur;
  final EntryType type;
  final String description;
  final String? createdAt;

  factory OtherExpenseLog.fromJson(JsonMap json) => OtherExpenseLog(
    id: jInt(json['id']),
    userId: jInt(json['userId']),
    date: jStr(json['date']),
    amountEur: jDouble(json['amountEur']),
    type: EntryType.fromJson(jStr(json['type'])),
    description: jStr(json['description']),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'userId': userId,
    'date': date,
    'amountEur': amountEur,
    'type': type.toJson(),
    'description': description,
    'createdAt': createdAt,
  };
}
