import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../mileage/mileage_controller.dart';
import 'rules_controller.dart';

/// Plan de kilometraje contratado y sus cambios programados.
/// Al programar o cancelar hay que invalidar además `rulesProvider` (es un
/// `FutureProvider` que no se entera solo) y los kilómetros, porque el cupo del
/// año cambia en cuanto se contrata el escalón nuevo.
class MileagePlanController extends AsyncNotifier<MileagePlansView> {
  @override
  Future<MileagePlansView> build() =>
      ref.read(mileagePlanServiceProvider).plans();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(mileagePlanServiceProvider).plans(),
    );
  }

  /// Programa el cambio para el día 1 del mes siguiente (el mes lo fija el servidor).
  Future<void> schedule({
    required int annualKmTotal,
    required double monthlyFeeEur,
  }) => _act(
    () => ref.read(mileagePlanServiceProvider).schedule(
      annualKmTotal: annualKmTotal,
      monthlyFeeEur: monthlyFeeEur,
    ),
  );

  /// Cancela el cambio aún no vigente.
  Future<void> cancelScheduled() =>
      _act(() => ref.read(mileagePlanServiceProvider).cancelScheduled());

  Future<void> _act(Future<MileagePlansView> Function() action) async {
    final view = await action();
    state = AsyncData(view);
    ref.invalidate(rulesProvider);
    ref.invalidate(mileageControllerProvider);
  }
}

final mileagePlanControllerProvider =
    AsyncNotifierProvider<MileagePlanController, MileagePlansView>(
      MileagePlanController.new,
    );
