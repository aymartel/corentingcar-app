import 'json_utils.dart';
import 'user.dart';

/// Parte del reparto de un repostaje para una persona (km del periodo y € a pagar).
class FuelPreviewPerUser {
  const FuelPreviewPerUser({
    required this.user,
    required this.km,
    required this.shareEur,
  });

  final User user;
  final double km;
  final double shareEur;

  factory FuelPreviewPerUser.fromJson(JsonMap json) => FuelPreviewPerUser(
    user: User.fromJson(asMap(json['user'])),
    km: jDouble(json['km']),
    shareEur: jDouble(json['shareEur']),
  );
}

/// Previsualización del reparto de gasolina por km (`GET /api/fuel/preview`).
/// Calculado por el backend, sin persistir; se muestra en vivo al teclear el importe.
class FuelPreview {
  const FuelPreview({
    required this.windowStartKm,
    required this.windowEndKm,
    required this.fallback,
    required this.perUser,
    required this.payerShareEur,
    required this.amountEur,
  });

  /// Odómetro del repostaje anterior (cota inferior); `null` si es el primero.
  final int? windowStartKm;

  /// Odómetro de este repostaje (cota superior).
  final int windowEndKm;

  /// `true` si no había km en el periodo y se repartió 50/50.
  final bool fallback;
  final List<FuelPreviewPerUser> perUser;

  /// Parte (€) que asume quien paga (el usuario logueado).
  final double payerShareEur;
  final double amountEur;

  factory FuelPreview.fromJson(JsonMap json) => FuelPreview(
    windowStartKm: jIntOrNull(json['windowStartKm']),
    windowEndKm: jInt(json['windowEndKm']),
    fallback: jBool(json['fallback']),
    perUser: asMapList(json['perUser']).map(FuelPreviewPerUser.fromJson).toList(),
    payerShareEur: jDouble(json['payerShareEur']),
    amountEur: jDouble(json['amountEur']),
  );
}
