import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_exception.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Estado de la sesión (Fase F3): cargando / sin sesión / autenticado.
sealed class SessionState {
  const SessionState();
}

/// Restaurando la sesión al arrancar.
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Sin sesión: se debe mostrar el login.
class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Sesión activa con el usuario autenticado.
class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  final User user;
}

/// Controla la identidad de la app (Fase F3). **Sin registro**: solo elige
/// perfil + valida PIN. Persiste la sesión y la restaura al abrir.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    // Sesión caducada (401 en cualquier petición) → volver a login (F10).
    ref.listen(sessionExpiredProvider, (_, _) {
      if (state is SessionAuthenticated) expireSession();
    });
    _restore();
    return const SessionLoading();
  }

  /// Restaura la sesión persistida al arrancar. Optimista: si hay usuario
  /// guardado, entra de inmediato (no vuelve a pedir PIN) y refresca en
  /// segundo plano; si el backend responde 401, cierra la sesión.
  Future<void> _restore() async {
    final store = ref.read(tokenStoreProvider);
    final token = await store.readToken();
    if (token == null || token.isEmpty) {
      state = const SessionUnauthenticated();
      return;
    }

    final stored = await store.readUser();
    if (stored != null) {
      state = SessionAuthenticated(stored);
    }

    try {
      final fresh = await ref.read(authServiceProvider).me();
      await store.saveUser(fresh);
      state = SessionAuthenticated(fresh);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await store.clear();
        state = const SessionUnauthenticated();
      } else if (stored == null) {
        // Sin usuario previo y el backend no responde: pedir login.
        state = const SessionUnauthenticated();
      }
      // Con usuario previo y error de red: se conserva la sesión optimista.
    }
  }

  /// Inicia sesión con perfil + PIN. Lanza [ApiException] si falla (la pantalla
  /// muestra el mensaje en español).
  Future<void> login(String profile, String pin) async {
    final result = await ref.read(authServiceProvider).login(profile, pin);
    await ref
        .read(tokenStoreProvider)
        .saveSession(token: result.token, user: result.user);
    state = SessionAuthenticated(result.user);
  }

  /// Sesión caducada (401): limpia el almacén local y vuelve a `unauthenticated`
  /// **sin** llamar al backend (el token ya no es válido).
  Future<void> expireSession() async {
    await ref.read(tokenStoreProvider).clear();
    state = const SessionUnauthenticated();
  }

  /// Cierra la sesión: invalida el token en el backend (best-effort), limpia el
  /// almacén y vuelve a `unauthenticated`.
  Future<void> logout() async {
    try {
      await ref.read(authServiceProvider).logout();
    } on ApiException {
      // Da igual si el backend no responde: limpiamos localmente igualmente.
    }
    await ref.read(tokenStoreProvider).clear();
    state = const SessionUnauthenticated();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Usuario autenticado (o null). Disponible globalmente para colores,
/// prioridad y "quién pide".
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionAuthenticated ? state.user : null;
});

/// Los 2 perfiles para elegir en el login (`GET /api/users`).
final usersProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(authServiceProvider).users(),
);
