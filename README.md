# CoRetingCar · App (Flutter)

App para que **dos personas** (Andy y Amigo) compartan un coche de renting sin discusiones: deja claro
cada día **quién tiene prioridad** y registra kilómetros, gasolina y lavado.

- **Tema**: dark/negro inspirado en la marca **JEEP**, moderno/futurista (ver `prompts/app/F0-design-system.md`).
- **Stack**: Flutter + Riverpod. La lógica (prioridad, agregados) la calcula el **backend**; la app presenta y avisa.
- **Backend desplegado**: `https://api.corentingcar.uk` (contrato bajo el prefijo `/api`).

## Requisitos

- Flutter SDK 3.38+ (Dart 3.10+). Comprueba con `flutter doctor`.
- Para el APK: Android SDK + un JDK (incluidos con Android Studio).

## Configuración por entorno (base URL)

La base URL se **inyecta en build** con `--dart-define=API_URL=<host>` (sin tocar código). La app le añade
el prefijo `/api`. Si no se indica, usa el valor por defecto de desarrollo.

| Entorno | `API_URL` | Notas |
|---|---|---|
| **dev** (por defecto) | `http://localhost:3000` | Backend local. En **emulador Android** usa `http://10.0.2.2:3000` (alias del host). |
| **staging** | `https://staging.api.corentingcar.uk` | Ejemplo; ajústalo a tu staging real. |
| **prod** | `https://api.corentingcar.uk` | Backend desplegado. |

> El backend debe permitir el **CORS**/origen de la app y servir por **https** en producción.

## Ejecutar en desarrollo

```bash
flutter pub get

# Con backend local (escritorio/web/Chrome):
flutter run --dart-define=API_URL=http://localhost:3000

# En un emulador Android (localhost del host = 10.0.2.2):
flutter run --dart-define=API_URL=http://10.0.2.2:3000

# Apuntando directamente al backend desplegado:
flutter run --dart-define=API_URL=https://api.corentingcar.uk
```

Si arrancas **sin** backend disponible, las pantallas muestran un estado de error con **reintento** (no
rompen) y el login indica que no pudo cargar los perfiles.

## Generar el APK (release)

```bash
# Producción (backend desplegado):
flutter build apk --release --dart-define=API_URL=https://api.corentingcar.uk

# Otros entornos:
flutter build apk --release --dart-define=API_URL=https://staging.api.corentingcar.uk
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Instálalo con:

```bash
flutter install --use-application-binary build/app/outputs/flutter-apk/app-release.apk
# o
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> Para reducir tamaño puedes dividir por ABI: `flutter build apk --release --split-per-abi --dart-define=API_URL=https://api.corentingcar.uk`.

## Icono y splash

Generados desde `assets/brand/` (parrilla de 7 ranuras verde sobre negro). Si cambias el arte:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Checklist de release

- [x] Permiso **INTERNET** en `android/app/src/main/AndroidManifest.xml` (necesario en release).
- [x] **Cleartext (http)** habilitado **solo en debug** (`src/debug/AndroidManifest.xml`); el release usa **https**.
- [x] `API_URL` de producción inyectada por `--dart-define` (no hardcodeada).
- [ ] El backend de producción acepta el origen de la app (CORS) y responde por https.
- [ ] Verificar: instalado el APK, el login entra y `GET /api/health` del backend responde `{"ok":true,...}`.

### Verificar el backend desplegado

```bash
curl https://api.corentingcar.uk/api/health
# → {"ok":true,"data":{"status":"ok","version":"..."}}
```

## Tests y análisis

```bash
flutter analyze
flutter test
```

## Estructura

```
lib/
  config/      env.dart (base URL por --dart-define)
  core/        constantes, formato es-ES
  data/        models/ (DTOs), api/ (cliente dio, token), services/, providers
  features/    today/ calendar/ mileage/ expenses/ login/ requests/ rules/ shell/
  common/
    theme/     tokens dark, tipografía (Rajdhani/Inter/JetBrains Mono)
    widgets/   brand/ (GrilleBars, PersonAvatar...), vistas async, GlowCard
```
