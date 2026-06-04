import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../calendar/calendar_controller.dart';
import '../today/today_controller.dart';

/// Lista de solicitudes de uso (Fase F8). Estados:
/// `pending → accepted | rejected | cancelled`. Avisos **solo in-app**.
class RequestsController extends AsyncNotifier<List<UseRequest>> {
  @override
  Future<List<UseRequest>> build() => ref.read(requestServiceProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(requestServiceProvider).list(),
    );
  }

  /// Acepta (solo el de prioridad): crea una cesión → refresca HOY y CALENDARIO.
  Future<void> accept(int id) => _act(
    () => ref.read(requestServiceProvider).accept(id),
    priorityChanged: true,
  );

  /// Rechaza (solo el de prioridad).
  Future<void> reject(int id) =>
      _act(() => ref.read(requestServiceProvider).reject(id));

  /// Cancela (solo el solicitante, si sigue pendiente).
  Future<void> cancel(int id) =>
      _act(() => ref.read(requestServiceProvider).cancel(id));

  Future<void> _act(
    Future<UseRequest> Function() action, {
    bool priorityChanged = false,
  }) async {
    await action();
    ref.invalidate(pendingRequestsProvider);
    if (priorityChanged) {
      // Aceptar = cesión: la prioridad efectiva de HOY y el CALENDARIO cambian.
      ref.invalidate(todayControllerProvider);
      ref.invalidate(calendarDaysProvider);
    }
    await refresh();
  }
}

final requestsControllerProvider =
    AsyncNotifierProvider<RequestsController, List<UseRequest>>(
      RequestsController.new,
    );

/// Pendientes dirigidas al usuario logueado (`GET /api/requests/pending`).
/// Alimenta el badge in-app.
final pendingRequestsProvider = FutureProvider<List<UseRequest>>(
  (ref) => ref.watch(requestServiceProvider).pending(),
);

/// Nº de pendientes que requieren acción del usuario (para el badge).
final pendingCountProvider = Provider<int>(
  (ref) => ref.watch(pendingRequestsProvider).asData?.value.length ?? 0,
);
