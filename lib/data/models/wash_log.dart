import 'json_utils.dart';

/// Lavado del coche (Fase F2). `POST /api/washes`. Alterna: uno cada uno.
class WashLog {
  const WashLog({
    required this.id,
    required this.userId,
    required this.date,
    this.costEur,
    this.createdAt,
  });

  final int id;
  final int userId;

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;

  /// Coste opcional (nullable).
  final double? costEur;
  final String? createdAt;

  factory WashLog.fromJson(JsonMap json) => WashLog(
    id: jInt(json['id']),
    userId: jInt(json['userId']),
    date: jStr(json['date']),
    costEur: jDoubleOrNull(json['costEur']),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'userId': userId,
    'date': date,
    'costEur': costEur,
    'createdAt': createdAt,
  };
}
