import '../api/api_client.dart';
import '../models/models.dart';

/// Registros de uso y agregado de km (Fase F2).
class UsageService {
  const UsageService(this._api);

  final ApiClient _api;

  /// `GET /api/usage` (filtros opcionales por `userId` y rango de fechas).
  Future<List<UsageLog>> list({int? userId, String? from, String? to}) async {
    final query = <String, dynamic>{
      'userId': ?userId,
      'from': ?from,
      'to': ?to,
    };
    final data = await _api.get('/usage', query: query.isEmpty ? null : query);
    return asMapList(data).map(UsageLog.fromJson).toList();
  }

  /// Odómetro actual = mayor `endKm` registrado (el odómetro solo sube). Sirve
  /// para prerrellenar el km inicial de un nuevo uso. Null si no hay registros.
  Future<int?> lastEndKm() async {
    final logs = await list();
    if (logs.isEmpty) return null;
    return logs.map((l) => l.endKm).reduce((a, b) => a > b ? a : b);
  }

  /// `POST /api/usage` `{ date, startKm, endKm, type }` (el servidor calcula
  /// `totalKm`).
  Future<UsageLog> create({
    required String date,
    required int startKm,
    required int endKm,
    required EntryType type,
  }) async {
    final data = await _api.post(
      '/usage',
      body: {
        'date': date,
        'startKm': startKm,
        'endKm': endKm,
        'type': type.toJson(),
      },
    );
    return UsageLog.fromJson(asMap(data));
  }

  /// `GET /api/mileage` — usados/restantes, compartidos, exceso por persona.
  Future<MileageSummary> mileage() async =>
      MileageSummary.fromJson(asMap(await _api.get('/mileage')));
}
