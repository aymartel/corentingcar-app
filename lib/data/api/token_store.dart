import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

/// Almacén seguro de la sesión (Fase F2/F3): token, perfil activo y usuario.
///
/// El interceptor del [ApiClient] usa [readToken] para añadir el Bearer; F3
/// escribe la sesión en login y la limpia en logout.
class TokenStore {
  const TokenStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const String _kToken = 'session_token';
  static const String _kProfile = 'active_profile';
  static const String _kUser = 'session_user';

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<void> saveToken(String token) =>
      _storage.write(key: _kToken, value: token);

  Future<String?> readProfile() => _storage.read(key: _kProfile);

  Future<void> saveProfile(String profile) =>
      _storage.write(key: _kProfile, value: profile);

  /// Usuario autenticado persistido (para restaurar la sesión al arrancar sin
  /// depender del backend).
  Future<void> saveUser(User user) =>
      _storage.write(key: _kUser, value: jsonEncode(user.toJson()));

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Guarda token + perfil + usuario en una sola operación (login).
  Future<void> saveSession({required String token, required User user}) async {
    await saveToken(token);
    await saveProfile(user.profile);
    await saveUser(user);
  }

  /// Limpia toda la sesión (logout / sesión caducada).
  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kProfile);
    await _storage.delete(key: _kUser);
  }
}
