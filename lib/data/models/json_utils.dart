/// Utilidades de (de)serialización JSON (Fase F2). El JSON externo va en
/// `camelCase` (ver `00-context-and-contract.md`).
library;

/// Mapa JSON genérico.
typedef JsonMap = Map<String, dynamic>;

/// Entero tolerante a `num` (el JSON puede traer `10` o `10.0`).
int jInt(Object? value) => (value as num).toInt();

int? jIntOrNull(Object? value) => value == null ? null : (value as num).toInt();

double jDouble(Object? value) => (value as num).toDouble();

double? jDoubleOrNull(Object? value) =>
    value == null ? null : (value as num).toDouble();

String jStr(Object? value) => value as String;

String? jStrOrNull(Object? value) => value as String?;

bool jBool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

/// Convierte un valor dinámico (de `dio`) en `JsonMap` de forma segura.
JsonMap asMap(Object? value) => (value as Map).cast<String, dynamic>();

/// Convierte una lista dinámica en `List<JsonMap>`.
List<JsonMap> asMapList(Object? value) =>
    (value as List).map((e) => asMap(e)).toList();
