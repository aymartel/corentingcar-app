import 'json_utils.dart';
import 'user.dart';

/// Prioridad de un día (Fase F2). `GET /api/priority/today` y
/// `GET /api/priority?date=`. La calcula el **backend** (fuente única).
class DailyPriority {
  const DailyPriority({
    required this.date,
    required this.priorityUser,
    required this.isMyDay,
    this.conflictPhrase,
    this.isHandover = false,
  });

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;

  /// Persona con prioridad ese día.
  final User priorityUser;

  /// Si el usuario logueado es el de prioridad.
  final bool isMyDay;

  /// Frase de resolución de conflicto en español (today la incluye).
  final String? conflictPhrase;

  /// Si la prioridad de la fecha proviene de un `handover` (cesión/cambio).
  final bool isHandover;

  factory DailyPriority.fromJson(JsonMap json) => DailyPriority(
    date: jStr(json['date']),
    priorityUser: User.fromJson(asMap(json['priorityUser'])),
    isMyDay: jBool(json['isMyDay']),
    conflictPhrase: jStrOrNull(json['conflictPhrase']),
    // El backend marca el origen con `source: 'rotation' | 'handover'`.
    isHandover: jStrOrNull(json['source']) == 'handover',
  );

  JsonMap toJson() => {
    'date': date,
    'priorityUser': priorityUser.toJson(),
    'isMyDay': isMyDay,
    'conflictPhrase': conflictPhrase,
    'isHandover': isHandover,
  };
}
