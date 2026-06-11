import '../api/api_client.dart';
import '../models/models.dart';

/// Cambios de uso con aprobación del otro usuario ("historial de usos").
/// `GET/POST/PATCH /api/usage/changes`. Máquina de estados:
/// `pending → approved|rejected|cancelled`. Avisos **solo in-app**.
class UsageChangeService {
  const UsageChangeService(this._api);

  final ApiClient _api;

  /// `GET /api/usage/changes?status=` — cambios en los que participa el usuario.
  Future<List<UsageChange>> list({UsageChangeStatus? status}) async {
    final data = await _api.get(
      '/usage/changes',
      query: status == null ? null : {'status': status.toJson()},
    );
    return asMapList(data).map(UsageChange.fromJson).toList();
  }

  /// `GET /api/usage/changes/pending` — pendientes dirigidos al usuario (badge).
  Future<List<UsageChange>> pending() async => asMapList(
    await _api.get('/usage/changes/pending'),
  ).map(UsageChange.fromJson).toList();

  /// Propone crear un uso pasado. Si el odómetro está desincronizado, el otro
  /// usuario debe aprobarlo antes de insertarse.
  Future<UsageChange> proposeCreate({
    required String date,
    required int startKm,
    required int endKm,
    required EntryType type,
    String? reason,
  }) async {
    final data = await _api.post(
      '/usage/changes',
      body: {
        'kind': 'create',
        'date': date,
        'startKm': startKm,
        'endKm': endKm,
        'type': type.toJson(),
        'reason': ?reason,
      },
    );
    return UsageChange.fromJson(asMap(data));
  }

  /// Propone editar un uso existente (requiere aprobación del otro usuario).
  Future<UsageChange> proposeUpdate({
    required int usageId,
    required String date,
    required int startKm,
    required int endKm,
    required EntryType type,
    String? reason,
  }) async {
    final data = await _api.post(
      '/usage/changes',
      body: {
        'kind': 'update',
        'usageId': usageId,
        'date': date,
        'startKm': startKm,
        'endKm': endKm,
        'type': type.toJson(),
        'reason': ?reason,
      },
    );
    return UsageChange.fromJson(asMap(data));
  }

  /// Propone eliminar un uso (requiere aprobación del otro usuario).
  Future<UsageChange> proposeDelete({required int usageId, String? reason}) async {
    final data = await _api.post(
      '/usage/changes',
      body: {'kind': 'delete', 'usageId': usageId, 'reason': ?reason},
    );
    return UsageChange.fromJson(asMap(data));
  }

  /// `PATCH /api/usage/changes/:id/approve` (solo el `recipient`).
  Future<UsageChange> approve(int id) async => UsageChange.fromJson(
    asMap(await _api.patch('/usage/changes/$id/approve')),
  );

  /// `PATCH /api/usage/changes/:id/reject` (solo el `recipient`).
  Future<UsageChange> reject(int id) async => UsageChange.fromJson(
    asMap(await _api.patch('/usage/changes/$id/reject')),
  );

  /// `PATCH /api/usage/changes/:id/cancel` (solo el `requester`, si sigue `pending`).
  Future<UsageChange> cancel(int id) async => UsageChange.fromJson(
    asMap(await _api.patch('/usage/changes/$id/cancel')),
  );
}
