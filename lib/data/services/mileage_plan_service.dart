import '../api/api_client.dart';
import '../models/models.dart';

/// Plan de kilometraje contratado y sus cambios con fecha de efecto.
/// `GET|POST /api/mileage/plans` y `DELETE /api/mileage/plans/scheduled`.
class MileagePlanService {
  const MileagePlanService(this._api);

  final ApiClient _api;

  /// Plan vigente, cambio programado, historial y catálogo de escalones.
  Future<MileagePlansView> plans() async =>
      MileagePlansView.fromJson(asMap(await _api.get('/mileage/plans')));

  /// Programa un cambio para el día 1 del mes siguiente (el mes lo calcula el servidor).
  Future<MileagePlansView> schedule({
    required int annualKmTotal,
    required double monthlyFeeEur,
  }) async {
    final data = await _api.post(
      '/mileage/plans',
      body: {'annualKmTotal': annualKmTotal, 'monthlyFeeEur': monthlyFeeEur},
    );
    return MileagePlansView.fromJson(asMap(data));
  }

  /// Cancela el cambio aún no vigente.
  Future<MileagePlansView> cancelScheduled() async =>
      MileagePlansView.fromJson(asMap(await _api.delete('/mileage/plans/scheduled')));
}
