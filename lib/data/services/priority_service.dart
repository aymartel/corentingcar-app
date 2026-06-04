import '../api/api_client.dart';
import '../models/models.dart';

/// Prioridad, calendario y cesiones (Fase F2). La calcula el **backend**.
class PriorityService {
  const PriorityService(this._api);

  final ApiClient _api;

  /// `GET /api/priority/today`.
  Future<DailyPriority> today() async =>
      DailyPriority.fromJson(asMap(await _api.get('/priority/today')));

  /// `GET /api/priority?date=YYYY-MM-DD`.
  Future<DailyPriority> at(String date) async => DailyPriority.fromJson(
    asMap(await _api.get('/priority', query: {'date': date})),
  );

  /// `GET /api/calendar?month=YYYY-MM` → días del mes.
  ///
  /// Acepta que el backend devuelva la lista directamente o envuelta en
  /// `{ days: [...] }`.
  Future<List<CalendarDay>> calendar(String month) async {
    final data = await _api.get('/calendar', query: {'month': month});
    final list = data is Map ? data['days'] : data;
    return asMapList(list).map(CalendarDay.fromJson).toList();
  }

  /// `POST /api/handovers` (upsert "el último gana").
  Future<void> setHandover({
    required String date,
    required int effectivePriorityUserId,
    required String origin,
  }) => _api.post(
    '/handovers',
    body: {
      'date': date,
      'effectivePriorityUserId': effectivePriorityUserId,
      'origin': origin,
    },
  );

  /// `DELETE /api/handovers/:date` — vuelve a la alternancia base.
  Future<void> deleteHandover(String date) => _api.delete('/handovers/$date');
}
