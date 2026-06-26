import 'json_utils.dart';
import 'user.dart';

/// Km de una persona (Fase F6, alineado al backend `GET /api/mileage`).
class PersonMileage {
  const PersonMileage({
    required this.user,
    required this.individualKm,
    required this.usedKm,
    required this.remainingKm,
    required this.exceeded,
    required this.excessKm,
    this.usedSinceStart = 0,
  });

  final User user;

  /// Km individuales registrados por la persona.
  final int individualKm;

  /// Km usados que cuentan para su cupo (individuales + su parte de compartidos).
  final int usedKm;
  final int remainingKm;

  /// Si la persona ha superado su cupo anual.
  final bool exceeded;

  /// Km de exceso a pagar (0 si no se ha superado).
  final int excessKm;

  /// Km usados ACUMULADOS desde el primer uso (individual + su parte de compartidos).
  final double usedSinceStart;

  factory PersonMileage.fromJson(JsonMap json) => PersonMileage(
    user: User.fromJson(asMap(json['user'])),
    individualKm: jInt(json['individualKm']),
    usedKm: jInt(json['usedKm']),
    remainingKm: jInt(json['remainingKm']),
    exceeded: jBool(json['exceeded']),
    excessKm: jInt(json['excessKm']),
    usedSinceStart: jDoubleOrNull(json['usedSinceStart']) ?? 0,
  );

  JsonMap toJson() => {
    'user': user.toJson(),
    'individualKm': individualKm,
    'usedKm': usedKm,
    'remainingKm': remainingKm,
    'exceeded': exceeded,
    'excessKm': excessKm,
    'usedSinceStart': usedSinceStart,
  };
}

/// Agregado anual de km (Fase F6). `GET /api/mileage`.
class MileageSummary {
  const MileageSummary({
    required this.people,
    required this.annualKmTotal,
    required this.annualKmPerPerson,
    required this.sharedKm,
    required this.sharedKmPerPerson,
    this.kmStartDate,
    this.daysSinceStart = 0,
    this.monthlyKmPerPerson = 0,
    this.dailyKmPerPerson = 0,
    this.recommendedToDate = 0,
  });

  /// Una entrada por persona (Andy y Dennis).
  final List<PersonMileage> people;

  /// Total anual (15.000) y cupo por persona (7.500).
  final int annualKmTotal;
  final int annualKmPerPerson;

  /// Km compartidos del año (total) y la parte que asume cada persona (50/50).
  final double sharedKm;
  final double sharedKmPerPerson;

  /// Fecha del primer uso (inicio del cómputo acumulado) y días transcurridos.
  final String? kmStartDate;
  final int daysSinceStart;

  /// Cupo aconsejado por persona: mensual (= anual/12) y diario (referencia).
  final int monthlyKmPerPerson;
  final double dailyKmPerPerson;

  /// Km aconsejados por persona ACUMULADOS hasta hoy desde el primer uso (cupo arrastrado).
  final double recommendedToDate;

  factory MileageSummary.fromJson(JsonMap json) => MileageSummary(
    people: asMapList(json['perUser']).map(PersonMileage.fromJson).toList(),
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    sharedKm: jDouble(json['sharedKm']),
    sharedKmPerPerson: jDouble(json['sharedKmPerPerson']),
    kmStartDate: jStrOrNull(json['kmStartDate']),
    daysSinceStart: jIntOrNull(json['daysSinceStart']) ?? 0,
    monthlyKmPerPerson: jIntOrNull(json['monthlyKmPerPerson']) ?? 0,
    dailyKmPerPerson: jDoubleOrNull(json['dailyKmPerPerson']) ?? 0,
    recommendedToDate: jDoubleOrNull(json['recommendedToDate']) ?? 0,
  );

  JsonMap toJson() => {
    'perUser': people.map((p) => p.toJson()).toList(),
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'sharedKm': sharedKm,
    'sharedKmPerPerson': sharedKmPerPerson,
    'kmStartDate': kmStartDate,
    'daysSinceStart': daysSinceStart,
    'monthlyKmPerPerson': monthlyKmPerPerson,
    'dailyKmPerPerson': dailyKmPerPerson,
    'recommendedToDate': recommendedToDate,
  };
}
