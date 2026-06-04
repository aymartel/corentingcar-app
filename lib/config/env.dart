import '../core/constants/app_constants.dart';

/// Configuración por entorno (Fase F2). **Deploy desde el inicio**: la base URL
/// se inyecta en build con `--dart-define`, sin recompilar lógica.
///
/// Comandos de ejecución:
/// ```sh
/// # Desarrollo (por defecto, localhost)
/// flutter run
/// # Android emulador (localhost del host = 10.0.2.2)
/// flutter run --dart-define=API_URL=http://10.0.2.2:3000
/// # Staging / producción
/// flutter run --dart-define=API_URL=https://api.coretingcar.example
/// flutter build apk --release --dart-define=API_URL=https://api.coretingcar.example
/// ```
abstract final class Env {
  Env._();

  /// Host raíz del backend (sin el prefijo `/api`). Configurable por entorno.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Base URL completa de la API (host + prefijo `/api` del contrato).
  static String get apiBaseUrl => '$apiUrl${AppConstants.apiPrefix}';

  /// Timeout de conexión/lectura/escritura de las peticiones.
  static const Duration timeout = Duration(seconds: 15);
}
