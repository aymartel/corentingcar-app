import '../api/api_client.dart';
import '../models/models.dart';

/// Gastos: gasolina y lavado (Fase F2).
class ExpensesService {
  const ExpensesService(this._api);

  final ApiClient _api;

  /// `GET /api/expenses` — saldo de gasolina + estado del lavado + historiales.
  Future<ExpensesSummary> summary() async =>
      ExpensesSummary.fromJson(asMap(await _api.get('/expenses')));

  /// `POST /api/fuel` `{ date, amountEur, odometerKm }`. Siempre compartido: el backend reparte
  /// el importe por los km de cada persona desde el último repostaje, según el odómetro del cuadro.
  Future<FuelLog> addFuel({
    required String date,
    required double amountEur,
    required int odometerKm,
  }) async {
    final data = await _api.post(
      '/fuel',
      body: {'date': date, 'amountEur': amountEur, 'odometerKm': odometerKm},
    );
    return FuelLog.fromJson(asMap(data));
  }

  /// `GET /api/fuel/preview?amountEur=&odometerKm=` — reparto por km sin persistir (vista en vivo).
  Future<FuelPreview> fuelPreview({
    required double amountEur,
    required int odometerKm,
  }) async {
    final data = await _api.get(
      '/fuel/preview',
      query: {'amountEur': amountEur, 'odometerKm': odometerKm},
    );
    return FuelPreview.fromJson(asMap(data));
  }

  /// `POST /api/washes` `{ date, costEur? }`.
  Future<WashLog> addWash({required String date, double? costEur}) async {
    final data = await _api.post(
      '/washes',
      body: {'date': date, 'costEur': ?costEur},
    );
    return WashLog.fromJson(asMap(data));
  }

  /// `POST /api/other-expenses` `{ date, amountEur, type, description }`.
  Future<OtherExpenseLog> addOtherExpense({
    required String date,
    required double amountEur,
    required EntryType type,
    required String description,
  }) async {
    final data = await _api.post(
      '/other-expenses',
      body: {
        'date': date,
        'amountEur': amountEur,
        'type': type.toJson(),
        'description': description,
      },
    );
    return OtherExpenseLog.fromJson(asMap(data));
  }

  /// `POST /api/settlements` — pago directo `fromUserId`→`toUserId` (saldar cuentas).
  Future<Settlement> addSettlement({
    required int fromUserId,
    required int toUserId,
    required String date,
    required double amountEur,
    String? note,
  }) async {
    final data = await _api.post(
      '/settlements',
      body: {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'date': date,
        'amountEur': amountEur,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return Settlement.fromJson(asMap(data));
  }

  /// `DELETE /api/settlements/:id` — elimina un pago directo (deshacer).
  Future<void> deleteSettlement(int id) async {
    await _api.delete('/settlements/$id');
  }

  // --- Incidencias (multas, golpes, averías) ---

  /// `GET /api/incidents` — abiertas primero. Normalmente basta con `summary()`.
  Future<List<Incident>> incidents({IncidentStatus? status}) async {
    final data = await _api.get(
      '/incidents',
      query: status == null ? null : {'status': status.toJson()},
    );
    return asMapList(data).map(Incident.fromJson).toList();
  }

  /// `POST /api/incidents` — nace ABIERTA. El importe es opcional.
  Future<Incident> addIncident({
    required String date,
    required IncidentKind kind,
    required String description,
    required EntryType type,
    double? amountEur,
    int? responsibleUserId,
  }) async {
    final data = await _api.post(
      '/incidents',
      body: {
        'date': date,
        'kind': kind.toJson(),
        'description': description,
        'type': type.toJson(),
        'amountEur': ?amountEur,
        'responsibleUserId': ?responsibleUserId,
      },
    );
    return Incident.fromJson(asMap(data));
  }

  /// `PATCH /api/incidents/:id` — edición parcial (p.ej. ponerle el importe).
  Future<Incident> updateIncident(
    int id, {
    String? date,
    IncidentKind? kind,
    String? description,
    EntryType? type,
    double? amountEur,
    int? responsibleUserId,
  }) async {
    final data = await _api.patch(
      '/incidents/$id',
      body: {
        'date': ?date,
        'kind': ?kind?.toJson(),
        'description': ?description,
        'type': ?type?.toJson(),
        'amountEur': ?amountEur,
        'responsibleUserId': ?responsibleUserId,
      },
    );
    return Incident.fromJson(asMap(data));
  }

  /// `PATCH /api/incidents/:id/resolve` — ya pagada o reparada: entra en el saldo.
  Future<Incident> resolveIncident(
    int id, {
    int? paidBy,
    double? amountEur,
  }) async {
    final data = await _api.patch(
      '/incidents/$id/resolve',
      body: {'paidBy': ?paidBy, 'amountEur': ?amountEur},
    );
    return Incident.fromJson(asMap(data));
  }

  /// `PATCH /api/incidents/:id/reopen` — su importe sale del saldo.
  Future<Incident> reopenIncident(int id) async {
    final data = await _api.patch('/incidents/$id/reopen');
    return Incident.fromJson(asMap(data));
  }

  /// `DELETE /api/incidents/:id`
  Future<void> deleteIncident(int id) async {
    await _api.delete('/incidents/$id');
  }
}
