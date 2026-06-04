import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../config/env.dart';
import 'api_exception.dart';

/// Lector del token de sesión (lo provee `TokenStore`).
typedef TokenReader = Future<String?> Function();

/// Cliente HTTP centralizado (Fase F2) sobre `dio`.
///
/// - Inyecta `Authorization: Bearer <token>` cuando hay sesión.
/// - Desempaqueta el **sobre** `{ ok, data }` / `{ ok, error }` del contrato.
/// - Convierte errores de red/negocio en [ApiException] con **mensaje en
///   español** para la UI.
class ApiClient {
  ApiClient({
    required TokenReader tokenReader,
    void Function()? onUnauthorized,
    Dio? dio,
  }) : _onUnauthorized = onUnauthorized,
       _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = Env.apiBaseUrl
      ..connectTimeout = Env.timeout
      ..receiveTimeout = Env.timeout
      ..sendTimeout = Env.timeout
      ..headers['Content-Type'] = 'application/json'
      // Inspeccionamos el sobre nosotros mismos (no lanzar en 4xx/5xx).
      ..validateStatus = (_) => true;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenReader();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // En web, el navegador revalida con ETag y devuelve 304 (cuerpo
          // vacío). Un parámetro único por GET evita la caché → siempre 200.
          if (kIsWeb && options.method.toUpperCase() == 'GET') {
            options.queryParameters = {
              ...options.queryParameters,
              '_': DateTime.now().microsecondsSinceEpoch.toString(),
            };
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  /// Se invoca cuando una petición devuelve 401 (sesión caducada). La app lo
  /// usa para volver al login (F10).
  final void Function()? _onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete(path, data: body));

  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    try {
      final res = await run();
      return _unwrap(res);
    } on DioException catch (e) {
      final mapped = _mapDioError(e);
      if (mapped.isUnauthorized) _onUnauthorized?.call();
      throw mapped;
    } on ApiException catch (e) {
      // 401 del sobre → sesión caducada: avisar para volver a login.
      if (e.isUnauthorized) _onUnauthorized?.call();
      rethrow;
    }
  }

  /// Devuelve `data` si el sobre es `ok`; si no, lanza [ApiException].
  dynamic _unwrap(Response<dynamic> res) {
    final body = res.data;
    final status = res.statusCode;

    if (body is Map) {
      if (body['ok'] == true) return body['data'];
      final error = body['error'];
      if (error is Map) {
        final code = (error['code'] as String?) ?? _codeForStatus(status);
        final message = error['message'] as String?;
        throw ApiException(
          code,
          _spanishMessage(message, status),
          statusCode: status,
        );
      }
    }

    // Respuesta fuera del sobre.
    if (status != null && status >= 200 && status < 300) return body;
    throw ApiException(
      _codeForStatus(status),
      _spanishMessage(null, status),
      statusCode: status,
    );
  }

  ApiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'TIMEOUT',
          'El servidor tardó demasiado en responder.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'NETWORK',
          'No hay conexión con el servidor.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          'NETWORK',
          'Conexión no segura con el servidor.',
        );
      case DioExceptionType.cancel:
        return const ApiException('CANCELLED', 'Petición cancelada.');
      case DioExceptionType.badResponse:
        return ApiException(
          _codeForStatus(e.response?.statusCode),
          _spanishMessage(null, e.response?.statusCode),
          statusCode: e.response?.statusCode,
        );
    }
  }

  /// Prefiere el mensaje (en español) del backend; si no, mapea por estado.
  String _spanishMessage(String? backendMessage, int? status) {
    if (backendMessage != null && backendMessage.trim().isNotEmpty) {
      return backendMessage;
    }
    switch (status) {
      case 400:
      case 422:
        return 'Datos no válidos.';
      case 401:
        return 'Sesión no válida o caducada.';
      case 403:
        return 'No tienes permiso para esta acción.';
      case 404:
        return 'No encontrado.';
      case 409:
        return 'La operación entra en conflicto con el estado actual.';
      case 429:
        return 'Demasiados intentos. Espera un momento.';
    }
    if (status != null && status >= 500) {
      return 'Error del servidor. Inténtalo más tarde.';
    }
    return 'Ha ocurrido un error inesperado.';
  }

  String _codeForStatus(int? status) {
    switch (status) {
      case 400:
      case 422:
        return 'VALIDATION_ERROR';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 429:
        return 'RATE_LIMITED';
    }
    if (status != null && status >= 500) return 'SERVER';
    return 'UNKNOWN';
  }
}
