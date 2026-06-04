import '../api/api_client.dart';
import '../models/models.dart';

/// Solicitudes de uso (Fase F2). Máquina de estados del contrato.
class RequestService {
  const RequestService(this._api);

  final ApiClient _api;

  /// `GET /api/requests?status=` (filtro opcional).
  Future<List<UseRequest>> list({RequestStatus? status}) async {
    final data = await _api.get(
      '/requests',
      query: status == null ? null : {'status': status.toJson()},
    );
    return asMapList(data).map(UseRequest.fromJson).toList();
  }

  /// `GET /api/requests/pending` — pendientes dirigidas al usuario (badge).
  Future<List<UseRequest>> pending() async => asMapList(
    await _api.get('/requests/pending'),
  ).map(UseRequest.fromJson).toList();

  /// `POST /api/requests` `{ useDate, message? }` → crea en `pending`.
  Future<UseRequest> create({required String useDate, String? message}) async {
    final data = await _api.post(
      '/requests',
      body: {'useDate': useDate, 'message': ?message},
    );
    return UseRequest.fromJson(asMap(data));
  }

  /// `PATCH /api/requests/:id/accept` (solo el `recipient`).
  Future<UseRequest> accept(int id) async =>
      UseRequest.fromJson(asMap(await _api.patch('/requests/$id/accept')));

  /// `PATCH /api/requests/:id/reject` (solo el `recipient`).
  Future<UseRequest> reject(int id) async =>
      UseRequest.fromJson(asMap(await _api.patch('/requests/$id/reject')));

  /// `PATCH /api/requests/:id/cancel` (solo el `requester`, si sigue `pending`).
  Future<UseRequest> cancel(int id) async =>
      UseRequest.fromJson(asMap(await _api.patch('/requests/$id/cancel')));
}
