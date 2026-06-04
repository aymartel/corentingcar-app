import 'json_utils.dart';
import 'user.dart';

/// Día del calendario mensual (Fase F2). `GET /api/calendar?month=YYYY-MM`.
/// La alternancia es continua y la calcula el backend.
class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.priorityUser,
    this.isHandover = false,
    this.origin,
  });

  /// Fecha ISO `YYYY-MM-DD`.
  final String date;

  /// Persona con prioridad efectiva ese día.
  final User priorityUser;

  /// Si el día tiene una cesión/cambio (`handover`).
  final bool isHandover;

  /// Origen del handover: `'manual' | 'request_accepted' | 'one_off_change'`.
  final String? origin;

  factory CalendarDay.fromJson(JsonMap json) {
    // El backend envía `handover: { origin, requestId } | null`.
    final handover = json['handover'];
    return CalendarDay(
      date: jStr(json['date']),
      priorityUser: User.fromJson(asMap(json['priorityUser'])),
      isHandover: handover != null,
      origin: handover is Map ? handover['origin'] as String? : null,
    );
  }

  JsonMap toJson() => {
    'date': date,
    'priorityUser': priorityUser.toJson(),
    'isHandover': isHandover,
    'origin': origin,
  };
}
