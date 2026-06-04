import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Resumen de gastos (Fase F7): saldo de gasolina + estado del lavado +
/// historiales. `GET /api/expenses`.
class ExpensesController extends AsyncNotifier<ExpensesSummary> {
  @override
  Future<ExpensesSummary> build() =>
      ref.read(expensesServiceProvider).summary();

  /// Recarga sin parpadeo (pull-to-refresh / tras registrar).
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(expensesServiceProvider).summary(),
    );
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, ExpensesSummary>(
      ExpensesController.new,
    );
