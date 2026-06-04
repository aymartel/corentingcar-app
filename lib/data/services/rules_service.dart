import '../api/api_client.dart';
import '../models/models.dart';

/// Reglas de solo lectura (Fase F2). `GET /api/rules`.
class RulesService {
  const RulesService(this._api);

  final ApiClient _api;

  Future<Rules> getRules() async =>
      Rules.fromJson(asMap(await _api.get('/rules')));
}
