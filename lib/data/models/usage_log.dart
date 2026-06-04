import 'entry_type.dart';
import 'json_utils.dart';

/// Registro de uso del coche (Fase F2). `GET/POST /api/usage`. El servidor
/// calcula `totalKm = endKm - startKm`.
class UsageLog {
  const UsageLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.startKm,
    required this.endKm,
    required this.totalKm,
    required this.type,
    this.createdAt,
  });

  final int id;
  final int userId;

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;
  final int startKm;
  final int endKm;
  final int totalKm;
  final EntryType type;
  final String? createdAt;

  factory UsageLog.fromJson(JsonMap json) => UsageLog(
    id: jInt(json['id']),
    userId: jInt(json['userId']),
    date: jStr(json['date']),
    startKm: jInt(json['startKm']),
    endKm: jInt(json['endKm']),
    totalKm: jInt(json['totalKm']),
    type: EntryType.fromJson(jStr(json['type'])),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'userId': userId,
    'date': date,
    'startKm': startKm,
    'endKm': endKm,
    'totalKm': totalKm,
    'type': type.toJson(),
    'createdAt': createdAt,
  };
}
