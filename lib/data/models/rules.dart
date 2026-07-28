import 'json_utils.dart';
import 'mileage_plan.dart';

/// Reglas/configuración del acuerdo (Fase F2). `GET /api/rules` (solo lectura).
/// JSON externo en `camelCase`; `feePerPerson` lo deriva el servidor (177,50).
class Rules {
  const Rules({
    required this.monthlyFeeEur,
    required this.feeSplitPct,
    required this.feePerPerson,
    required this.annualKmTotal,
    required this.annualKmPerPerson,
    required this.kmWindow,
    required this.sharedKmRounding,
    required this.anchorDate,
    required this.anchorUserId,
    required this.firstWashUserId,
    required this.timezone,
    this.updatedAt,
    this.kmPlan,
    this.scheduledKmPlan,
  });

  final double monthlyFeeEur;
  final double feeSplitPct;

  /// Derivado en servidor: `monthlyFeeEur * feeSplitPct / 100` (= 177,50).
  final double feePerPerson;
  final int annualKmTotal;
  final int annualKmPerPerson;

  /// Ventana de cómputo de km (`'natural'` = año natural).
  final String kmWindow;
  final int sharedKmRounding;

  /// Fecha ISO `YYYY-MM-DD` desde la que arranca la alternancia.
  final String anchorDate;
  final int anchorUserId;
  final int firstWashUserId;

  /// Zona horaria que define qué es "hoy" (`'Europe/Madrid'`).
  final String timezone;
  final String? updatedAt;

  /// Plan de kilometraje vigente hoy. `null` si el backend es anterior a esta feature.
  final MileagePlan? kmPlan;

  /// Cambio de plan programado para un mes futuro, si lo hay.
  final MileagePlan? scheduledKmPlan;

  factory Rules.fromJson(JsonMap json) => Rules(
    monthlyFeeEur: jDouble(json['monthlyFeeEur']),
    feeSplitPct: jDouble(json['feeSplitPct']),
    feePerPerson: jDouble(json['feePerPerson']),
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    kmWindow: jStr(json['kmWindow']),
    sharedKmRounding: jInt(json['sharedKmRounding']),
    anchorDate: jStr(json['anchorDate']),
    anchorUserId: jInt(json['anchorUserId']),
    firstWashUserId: jInt(json['firstWashUserId']),
    timezone: jStr(json['timezone']),
    updatedAt: jStrOrNull(json['updatedAt']),
    kmPlan: json['kmPlan'] == null
        ? null
        : MileagePlan.fromJson(asMap(json['kmPlan'])),
    scheduledKmPlan: json['scheduledKmPlan'] == null
        ? null
        : MileagePlan.fromJson(asMap(json['scheduledKmPlan'])),
  );

  JsonMap toJson() => {
    'monthlyFeeEur': monthlyFeeEur,
    'feeSplitPct': feeSplitPct,
    'feePerPerson': feePerPerson,
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'kmWindow': kmWindow,
    'sharedKmRounding': sharedKmRounding,
    'anchorDate': anchorDate,
    'anchorUserId': anchorUserId,
    'firstWashUserId': firstWashUserId,
    'timezone': timezone,
    'updatedAt': updatedAt,
    'kmPlan': kmPlan?.toJson(),
    'scheduledKmPlan': scheduledKmPlan?.toJson(),
  };
}
