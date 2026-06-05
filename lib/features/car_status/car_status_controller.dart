import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Disponibilidad real del coche (Fase F12). "¿Está libre ahora?" — distinto de
/// la prioridad del día. El estado lo lleva el backend (`GET /api/car-status`).
class CarStatusController extends AsyncNotifier<CarStatus> {
  @override
  Future<CarStatus> build() => ref.read(carStatusServiceProvider).getStatus();

  /// Recarga sin parpadeo (pull-to-refresh / onResume / reintento).
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(carStatusServiceProvider).getStatus(),
    );
  }

  /// "Tengo el coche" → lo marco como ocupado por mí.
  Future<void> take() async {
    state = AsyncData(
      await ref.read(carStatusServiceProvider).setStatus(CarAvailability.taken),
    );
  }

  /// "Lo dejo libre" → lo marco libre indicando el parqueo (y nota opcional).
  /// El registro de uso (km) lo hace el modal **antes** de llamar aquí.
  Future<void> release({required ParkingSpot parking, String? note}) async {
    state = AsyncData(
      await ref
          .read(carStatusServiceProvider)
          .setStatus(CarAvailability.free, parking: parking, note: note),
    );
  }
}

final carStatusProvider =
    AsyncNotifierProvider<CarStatusController, CarStatus>(
      CarStatusController.new,
    );
