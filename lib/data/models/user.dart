import 'json_utils.dart';

/// Perfil de usuario (Fase F2). `GET /api/users` y `auth`. **Nunca** incluye
/// `pin_hash`.
class User {
  const User({
    required this.id,
    required this.name,
    required this.profile,
    this.color,
  });

  final int id;

  /// Nombre visible (`'Andy'` | `'Dennis'`).
  final String name;

  /// Identificador estable: `'user1'` | `'user2'`.
  final String profile;

  /// Color hex de la UI/calendario (canónico F0). Puede venir nulo.
  final String? color;

  factory User.fromJson(JsonMap json) => User(
    id: jInt(json['id']),
    name: jStr(json['name']),
    profile: jStr(json['profile']),
    color: jStrOrNull(json['color']),
  );

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'profile': profile,
    'color': color,
  };
}
