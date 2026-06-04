import '../api/api_client.dart';
import '../models/models.dart';

/// Resultado del login: token de sesión + usuario autenticado.
typedef LoginResult = ({String token, User user});

/// Identidad y perfiles (Fase F2). `auth` y `users` del contrato.
class AuthService {
  const AuthService(this._api);

  final ApiClient _api;

  /// `POST /api/auth/login` `{ profile, pin }` → `{ token, user }`.
  Future<LoginResult> login(String profile, String pin) async {
    final data = asMap(
      await _api.post('/auth/login', body: {'profile': profile, 'pin': pin}),
    );
    return (
      token: jStr(data['token']),
      user: User.fromJson(asMap(data['user'])),
    );
  }

  /// `POST /api/auth/logout` — invalida el token de sesión.
  Future<void> logout() => _api.post('/auth/logout');

  /// `GET /api/auth/me` — usuario autenticado a partir del token.
  Future<User> me() async => User.fromJson(asMap(await _api.get('/auth/me')));

  /// `GET /api/users` — los 2 perfiles (sin `pin_hash`).
  Future<List<User>> users() async =>
      asMapList(await _api.get('/users')).map(User.fromJson).toList();
}
