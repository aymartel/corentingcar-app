import '../api/api_client.dart';
import '../models/models.dart';

/// Disponibilidad real del coche (Fase F12). El estado es el **último evento**;
/// lo lleva el backend.
class CarStatusService {
  const CarStatusService(this._api);

  final ApiClient _api;

  /// `GET /api/car-status` → estado actual.
  Future<CarStatus> getStatus() async =>
      CarStatus.fromJson(asMap(await _api.get('/car-status')));

  /// `POST /api/car-status` `{ status, parking?, note? }` → nuevo estado.
  /// Lo fija quien actúa (token logueado).
  Future<CarStatus> setStatus(
    CarAvailability availability, {
    ParkingSpot? parking,
    String? note,
  }) async {
    final data = await _api.post(
      '/car-status',
      body: {
        'status': availability.toJson(),
        'parking': ?parking?.toJson(),
        'note': ?note,
      },
    );
    return CarStatus.fromJson(asMap(data));
  }
}
