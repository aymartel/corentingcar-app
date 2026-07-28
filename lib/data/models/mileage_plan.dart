import 'json_utils.dart';
import 'user.dart';

/// Plan de kilometraje contratado. Los escalones son ANUALES (15.000 / 20.000 / 25.000 km al
/// año): lo mensual se deriva dividiendo entre 12 y lo de cada persona entre 2 más
/// (25.000 → 2.083 km/mes → 1.041,67 por persona). `GET /api/mileage/plans`.
class MileagePlan {
  const MileagePlan({
    required this.annualKmTotal,
    required this.annualKmPerPerson,
    required this.monthlyKmTotal,
    required this.monthlyKmPerPerson,
    required this.monthlyFeeEur,
    required this.feePerPerson,
    this.id,
    this.effectiveMonth,
    this.createdBy,
    this.createdAt,
  });

  /// `null` en la línea base (el plan con el que arrancó el acuerdo).
  final int? id;

  /// Mes `YYYY-MM` desde el que rige; `null` en la línea base ("desde el inicio").
  final String? effectiveMonth;
  final int annualKmTotal;
  final int annualKmPerPerson;

  /// Cupo mensual de los dos = anual / 12 (25.000 → 2.083).
  final int monthlyKmTotal;

  /// Cupo mensual por persona = anual / 24, con decimales (25.000 → 1.041,67).
  final double monthlyKmPerPerson;
  final double monthlyFeeEur;
  final double feePerPerson;

  /// Quién programó el cambio (`null` en la línea base).
  final User? createdBy;
  final String? createdAt;

  factory MileagePlan.fromJson(JsonMap json) => MileagePlan(
    id: jIntOrNull(json['id']),
    effectiveMonth: jStrOrNull(json['effectiveMonth']),
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    monthlyKmTotal: jInt(json['monthlyKmTotal']),
    monthlyKmPerPerson: jDouble(json['monthlyKmPerPerson']),
    monthlyFeeEur: jDouble(json['monthlyFeeEur']),
    feePerPerson: jDouble(json['feePerPerson']),
    createdBy: json['createdBy'] == null
        ? null
        : User.fromJson(asMap(json['createdBy'])),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'effectiveMonth': effectiveMonth,
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'monthlyKmTotal': monthlyKmTotal,
    'monthlyKmPerPerson': monthlyKmPerPerson,
    'monthlyFeeEur': monthlyFeeEur,
    'feePerPerson': feePerPerson,
    'createdBy': createdBy?.toJson(),
    'createdAt': createdAt,
  };
}

/// Escalón del catálogo, con su impacto ya calculado por el servidor.
class MileagePlanOption {
  const MileagePlanOption({
    required this.annualKmTotal,
    required this.annualKmPerPerson,
    required this.monthlyKmTotal,
    required this.monthlyKmPerPerson,
    required this.monthlyFeeEur,
    required this.feePerPerson,
    required this.extraFeeEur,
    required this.feeDeltaEur,
    required this.isCurrent,
    required this.isScheduled,
  });

  final int annualKmTotal;
  final int annualKmPerPerson;
  final int monthlyKmTotal;
  final double monthlyKmPerPerson;
  final double monthlyFeeEur;
  final double feePerPerson;

  /// Sobrecoste frente al escalón más barato (0 / 30 / 70), como en la app del renting.
  final double extraFeeEur;

  /// Diferencia de cuota frente al plan vigente (negativa al bajar de escalón).
  final double feeDeltaEur;
  final bool isCurrent;
  final bool isScheduled;

  factory MileagePlanOption.fromJson(JsonMap json) => MileagePlanOption(
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    monthlyKmTotal: jInt(json['monthlyKmTotal']),
    monthlyKmPerPerson: jDouble(json['monthlyKmPerPerson']),
    monthlyFeeEur: jDouble(json['monthlyFeeEur']),
    feePerPerson: jDouble(json['feePerPerson']),
    extraFeeEur: jDouble(json['extraFeeEur']),
    feeDeltaEur: jDouble(json['feeDeltaEur']),
    isCurrent: jBool(json['isCurrent']),
    isScheduled: jBool(json['isScheduled']),
  );

  JsonMap toJson() => {
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'monthlyKmTotal': monthlyKmTotal,
    'monthlyKmPerPerson': monthlyKmPerPerson,
    'monthlyFeeEur': monthlyFeeEur,
    'feePerPerson': feePerPerson,
    'extraFeeEur': extraFeeEur,
    'feeDeltaEur': feeDeltaEur,
    'isCurrent': isCurrent,
    'isScheduled': isScheduled,
  };
}

/// Respuesta completa de `GET /api/mileage/plans`.
class MileagePlansView {
  const MileagePlansView({
    required this.current,
    required this.history,
    required this.options,
    this.scheduled,
  });

  /// Plan vigente hoy.
  final MileagePlan current;

  /// Cambio programado para un mes futuro, si lo hay (solo puede haber uno).
  final MileagePlan? scheduled;

  /// Línea base + todos los cambios, del más reciente al más antiguo.
  final List<MileagePlan> history;
  final List<MileagePlanOption> options;

  factory MileagePlansView.fromJson(JsonMap json) => MileagePlansView(
    current: MileagePlan.fromJson(asMap(json['current'])),
    scheduled: json['scheduled'] == null
        ? null
        : MileagePlan.fromJson(asMap(json['scheduled'])),
    history: asMapList(json['history']).map(MileagePlan.fromJson).toList(),
    options: asMapList(json['options']).map(MileagePlanOption.fromJson).toList(),
  );

  JsonMap toJson() => {
    'current': current.toJson(),
    'scheduled': scheduled?.toJson(),
    'history': history.map((p) => p.toJson()).toList(),
    'options': options.map((o) => o.toJson()).toList(),
  };
}
