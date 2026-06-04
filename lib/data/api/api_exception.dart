/// Excepción de la capa de datos (Fase F2) con **mensaje en español** listo
/// para mostrar en la UI. `code` es estable (del backend o de red).
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});

  /// Código estable: del sobre `{ error: { code } }` o de red
  /// (`NETWORK`, `TIMEOUT`, `UNAUTHORIZED`, `VALIDATION_ERROR`, `SERVER`...).
  final String code;

  /// Mensaje en español para mostrar al usuario.
  final String message;

  /// Código HTTP, si lo hubo.
  final int? statusCode;

  /// Sesión inválida/caducada → la UI debe volver a login (ver F3/F10).
  bool get isUnauthorized => statusCode == 401 || code == 'UNAUTHORIZED';

  @override
  String toString() => 'ApiException($code, "$message", status: $statusCode)';
}
