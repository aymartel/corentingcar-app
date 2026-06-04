import '../api/api_client.dart';
import '../models/models.dart';

/// Gastos: gasolina y lavado (Fase F2).
class ExpensesService {
  const ExpensesService(this._api);

  final ApiClient _api;

  /// `GET /api/expenses` — saldo de gasolina + estado del lavado + historiales.
  Future<ExpensesSummary> summary() async =>
      ExpensesSummary.fromJson(asMap(await _api.get('/expenses')));

  /// `POST /api/fuel` `{ date, amountEur, type }`.
  Future<FuelLog> addFuel({
    required String date,
    required double amountEur,
    required EntryType type,
  }) async {
    final data = await _api.post(
      '/fuel',
      body: {'date': date, 'amountEur': amountEur, 'type': type.toJson()},
    );
    return FuelLog.fromJson(asMap(data));
  }

  /// `POST /api/washes` `{ date, costEur? }`.
  Future<WashLog> addWash({required String date, double? costEur}) async {
    final data = await _api.post(
      '/washes',
      body: {'date': date, 'costEur': ?costEur},
    );
    return WashLog.fromJson(asMap(data));
  }
}
