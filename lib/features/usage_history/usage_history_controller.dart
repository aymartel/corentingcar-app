import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../login/session_controller.dart';
import '../mileage/mileage_controller.dart';

/// Historial de TODOS los usos (de ambos usuarios). `GET /api/usage` sin filtro.
class UsageHistoryController extends AsyncNotifier<List<UsageLog>> {
  @override
  Future<List<UsageLog>> build() => ref.read(usageServiceProvider).list();

  /// Recarga sin parpadeo (pull-to-refresh / reintento).
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(usageServiceProvider).list());
  }
}

final usageHistoryControllerProvider =
    AsyncNotifierProvider<UsageHistoryController, List<UsageLog>>(
      UsageHistoryController.new,
    );

/// Cambios de uso (crear/editar/eliminar) con aprobación del otro usuario.
/// `GET /api/usage/changes`. Estados: `pending → approved|rejected|cancelled`.
class UsageChangesController extends AsyncNotifier<List<UsageChange>> {
  @override
  Future<List<UsageChange>> build() =>
      ref.read(usageChangeServiceProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(usageChangeServiceProvider).list(),
    );
  }

  /// El recipient aprueba (aplica el cambio sobre `usage_logs`).
  Future<void> approve(int id) =>
      _act(() => ref.read(usageChangeServiceProvider).approve(id));

  /// El recipient rechaza.
  Future<void> reject(int id) =>
      _act(() => ref.read(usageChangeServiceProvider).reject(id));

  /// El requester cancela su propio cambio pendiente.
  Future<void> cancel(int id) =>
      _act(() => ref.read(usageChangeServiceProvider).cancel(id));

  Future<void> _act(Future<UsageChange> Function() action) async {
    await action();
    ref.invalidate(pendingUsageChangesProvider);
    // Aprobar aplica el cambio sobre usage_logs → refrescar historial y kilómetros.
    ref.invalidate(usageHistoryControllerProvider);
    ref.invalidate(mileageControllerProvider);
    await refresh();
  }
}

final usageChangesControllerProvider =
    AsyncNotifierProvider<UsageChangesController, List<UsageChange>>(
      UsageChangesController.new,
    );

/// Cambios pendientes dirigidos al usuario (`GET /api/usage/changes/pending`).
/// Alimenta el badge in-app junto a las solicitudes (avisos solo in-app).
final pendingUsageChangesProvider = FutureProvider<List<UsageChange>>(
  (ref) => ref.watch(usageChangeServiceProvider).pending(),
);

/// Nombre del OTRO usuario (para los diálogos de aprobación). Best-effort:
/// cae a un genérico si aún no se cargaron los usuarios o no hay sesión.
String otherUserName(WidgetRef ref) {
  final me = ref.read(currentUserProvider);
  final users = ref.read(allUsersProvider).asData?.value;
  if (users != null && me != null) {
    for (final u in users) {
      if (u.id != me.id) return u.name;
    }
  }
  return 'el otro usuario';
}
