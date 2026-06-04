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
  });

  final User user;

  /// Km individuales registrados por la persona.
  final int individualKm;

  /// Km usados que cuentan para su cupo (individuales + su parte de compartidos).
  final int usedKm;
  final int remainingKm;

  /// Si la persona ha superado su cupo (8.000).
  final bool exceeded;

  /// Km de exceso a pagar (0 si no se ha superado).
  final int excessKm;

  factory PersonMileage.fromJson(JsonMap json) => PersonMileage(
    user: User.fromJson(asMap(json['user'])),
    individualKm: jInt(json['individualKm']),
    usedKm: jInt(json['usedKm']),
    remainingKm: jInt(json['remainingKm']),
    exceeded: jBool(json['exceeded']),
    excessKm: jInt(json['excessKm']),
  );

  JsonMap toJson() => {
    'user': user.toJson(),
    'individualKm': individualKm,
    'usedKm': usedKm,
    'remainingKm': remainingKm,
    'exceeded': exceeded,
    'excessKm': excessKm,
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
  });

  /// Una entrada por persona (Andy y Dennis).
  final List<PersonMileage> people;

  /// Total anual (16.000) y cupo por persona (8.000).
  final int annualKmTotal;
  final int annualKmPerPerson;

  /// Km compartidos del año (total) y la parte que asume cada persona (50/50).
  final double sharedKm;
  final double sharedKmPerPerson;

  factory MileageSummary.fromJson(JsonMap json) => MileageSummary(
    people: asMapList(json['perUser']).map(PersonMileage.fromJson).toList(),
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    sharedKm: jDouble(json['sharedKm']),
    sharedKmPerPerson: jDouble(json['sharedKmPerPerson']),
  );

  JsonMap toJson() => {
    'perUser': people.map((p) => p.toJson()).toList(),
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'sharedKm': sharedKm,
    'sharedKmPerPerson': sharedKmPerPerson,
  };
}
