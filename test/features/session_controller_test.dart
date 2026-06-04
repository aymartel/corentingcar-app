import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/providers.dart';
import 'package:coretingcar/features/login/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Crea un container con los fakes inyectados y espera a que la restauración
/// inicial termine (sale de `SessionLoading`).
Future<ProviderContainer> _settledContainer({
  required FakeTokenStore store,
  required FakeAuthService auth,
}) async {
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(store),
      authServiceProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  // Dispara build() + _restore().
  container.read(sessionControllerProvider);
  for (var i = 0; i < 10; i++) {
    if (container.read(sessionControllerProvider) is! SessionLoading) break;
    await Future<void>.delayed(Duration.zero);
  }
  return container;
}

void main() {
  group('SessionController · restauración', () {
    test('sin token → unauthenticated', () async {
      final container = await _settledContainer(
        store: FakeTokenStore(),
        auth: FakeAuthService(),
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
    });

    test('token + usuario guardados → authenticated', () async {
      final container = await _settledContainer(
        store: FakeTokenStore(token: 't', user: andy),
        auth: FakeAuthService(meUser: andy),
      );
      final state = container.read(sessionControllerProvider);
      expect(state, isA<SessionAuthenticated>());
      expect((state as SessionAuthenticated).user.profile, 'andy');
      expect(container.read(currentUserProvider)?.profile, 'andy');
    });

    test('error de red con usuario previo → conserva la sesión', () async {
      final container = await _settledContainer(
        store: FakeTokenStore(token: 't', user: andy),
        auth: FakeAuthService(
          meError: const ApiException('NETWORK', 'Sin conexión'),
        ),
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionAuthenticated>(),
      );
    });

    test('401 al restaurar → limpia y unauthenticated', () async {
      final store = FakeTokenStore(token: 't', user: andy);
      final container = await _settledContainer(
        store: store,
        auth: FakeAuthService(
          meError: const ApiException('UNAUTHORIZED', 'x', statusCode: 401),
        ),
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
      expect(await store.readToken(), isNull);
    });
  });

  group('SessionController · login / logout', () {
    test('login válido → authenticated y persiste la sesión', () async {
      final store = FakeTokenStore();
      final container = await _settledContainer(
        store: store,
        auth: FakeAuthService(),
      );

      await container
          .read(sessionControllerProvider.notifier)
          .login('andy', '1234');

      final state = container.read(sessionControllerProvider);
      expect(state, isA<SessionAuthenticated>());
      expect((state as SessionAuthenticated).user.profile, 'andy');
      expect(await store.readToken(), 'token-andy');
      expect((await store.readUser())?.profile, 'andy');
    });

    test('PIN inválido → lanza y NO autentica', () async {
      final container = await _settledContainer(
        store: FakeTokenStore(),
        auth: FakeAuthService(
          loginError: const ApiException(
            'UNAUTHORIZED',
            'PIN incorrecto',
            statusCode: 401,
          ),
        ),
      );

      await expectLater(
        container
            .read(sessionControllerProvider.notifier)
            .login('andy', '0000'),
        throwsA(isA<ApiException>()),
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
    });

    test('logout limpia la sesión y vuelve a unauthenticated', () async {
      final store = FakeTokenStore(token: 't', user: andy);
      final auth = FakeAuthService(meUser: andy);
      final container = await _settledContainer(store: store, auth: auth);
      expect(
        container.read(sessionControllerProvider),
        isA<SessionAuthenticated>(),
      );

      await container.read(sessionControllerProvider.notifier).logout();

      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
      expect(await store.readToken(), isNull);
      expect(auth.logoutCalls, 1);
    });

    test('sesión caducada (401) expira la sesión y limpia el token', () async {
      final store = FakeTokenStore(token: 't', user: andy);
      final container = await _settledContainer(
        store: store,
        auth: FakeAuthService(meUser: andy),
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionAuthenticated>(),
      );

      // Un 401 en cualquier petición emite la señal.
      container.read(sessionExpiredProvider.notifier).notifyExpired();
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
      expect(await store.readToken(), isNull);
    });
  });
}
