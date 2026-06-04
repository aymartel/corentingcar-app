import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formato de presentación **es-ES** (Fase F1): miles con punto, decimales con
/// coma, € con coma. **Solo para la UI**; el JSON viaja con números crudos
/// (ver `00-context-and-contract.md` · §7).
///
/// Requiere `initializeDateFormatting(AppConstants.intlLocale)` en `main()`
/// para las fechas.
abstract final class EsFormat {
  EsFormat._();

  static const String _l = AppConstants.intlLocale;

  static final NumberFormat _km = NumberFormat('#,##0', _l);
  static final NumberFormat _euro = NumberFormat.currency(
    locale: _l,
    symbol: '€',
    decimalDigits: 2,
  );
  static final NumberFormat _decimal = NumberFormat('#,##0.#', _l);

  /// Kilómetros sin decimales: `12480` → `"12.480"`.
  static String km(num value) => _km.format(value);

  /// Importe en euros: `177.5` → `"177,50 €"`.
  static String euro(num value) => _euro.format(value);

  /// Número con hasta 1 decimal (p.ej. km compartidos repartidos).
  static String decimal(num value) => _decimal.format(value);

  /// Fecha larga: `"4 jun 2026"`.
  static String date(DateTime date) => DateFormat('d MMM y', _l).format(date);

  /// Fecha completa con día de la semana: `"jueves, 4 de junio"`.
  static String weekday(DateTime date) =>
      DateFormat("EEEE, d 'de' MMMM", _l).format(date);

  /// Parámetro de mes para la API: `"2026-06"` (`YYYY-MM`).
  static String apiMonth(DateTime date) => DateFormat('yyyy-MM').format(date);

  /// Fecha ISO para la API: `"2026-06-04"` (`YYYY-MM-DD`).
  static String apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Parsea un importe escrito por el usuario (acepta coma o punto decimal).
  /// Si hay coma, se trata como decimal (y el punto como separador de miles).
  /// Devuelve null si no es un número válido.
  static double? parseAmount(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// Mes y año en español: `"junio 2026"` (sin capitalizar; capitaliza la UI).
  static String monthYear(DateTime date) =>
      DateFormat('MMMM y', _l).format(date);

  /// Iniciales de los días de la semana (lunes primero).
  static const List<String> weekdayInitials = [
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];
}
