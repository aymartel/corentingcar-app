import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api.dart';
import 'models/models.dart';
import 'services/services.dart';

/// Providers base de la capa de datos (Fase F2): token store, cliente HTTP y
/// servicios por dominio. Las fases siguientes (F3+) construyen
/// `Notifier`/`AsyncNotifier` encima de estos servicios.

/// Almacén seguro del token de sesión.
final tokenStoreProvider = Provider<TokenStore>((ref) => const TokenStore());

/// Señal de **sesión caducada** (F10): el cliente HTTP la emite al recibir un
/// 401; el `SessionController` la escucha para volver al login. Vive en la capa
/// de datos para no acoplarla a `features/`.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyExpired() => state = state + 1;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(
  SessionExpiredNotifier.new,
);

/// Cliente HTTP centralizado, con el interceptor del Bearer enlazado al store y
/// el aviso de 401 (sesión caducada).
final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.watch(tokenStoreProvider);
  return ApiClient(
    tokenReader: store.readToken,
    onUnauthorized: () =>
        ref.read(sessionExpiredProvider.notifier).notifyExpired(),
  );
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

final rulesServiceProvider = Provider<RulesService>(
  (ref) => RulesService(ref.watch(apiClientProvider)),
);

final priorityServiceProvider = Provider<PriorityService>(
  (ref) => PriorityService(ref.watch(apiClientProvider)),
);

final usageServiceProvider = Provider<UsageService>(
  (ref) => UsageService(ref.watch(apiClientProvider)),
);

final usageChangeServiceProvider = Provider<UsageChangeService>(
  (ref) => UsageChangeService(ref.watch(apiClientProvider)),
);

final mileagePlanServiceProvider = Provider<MileagePlanService>(
  (ref) => MileagePlanService(ref.watch(apiClientProvider)),
);

final expensesServiceProvider = Provider<ExpensesService>(
  (ref) => ExpensesService(ref.watch(apiClientProvider)),
);

final requestServiceProvider = Provider<RequestService>(
  (ref) => RequestService(ref.watch(apiClientProvider)),
);

final carStatusServiceProvider = Provider<CarStatusService>(
  (ref) => CarStatusService(ref.watch(apiClientProvider)),
);

/// Los 2 perfiles (`GET /api/users`), cacheados a nivel de app para resolver
/// nombres/colores por `id` en historiales (gasolina, lavado, solicitudes).
final allUsersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authServiceProvider).users(),
);

/// Usuarios indexados por `id` (derivado de [allUsersProvider]).
final usersByIdProvider = Provider<AsyncValue<Map<int, User>>>(
  (ref) => ref
      .watch(allUsersProvider)
      .whenData((users) => {for (final u in users) u.id: u}),
);

/// Odómetro actual del coche = mayor `endKm` registrado (la última cifra del
/// cuentakilómetros). Se muestra en HOY. Se invalida al registrar un uso.
final currentOdometerProvider = FutureProvider<int?>(
  (ref) => ref.watch(usageServiceProvider).lastEndKm(),
);
