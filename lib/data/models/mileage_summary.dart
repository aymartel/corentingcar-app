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

  /// Si la persona ha superado su cupo anual.
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

/// Uso de una persona en un mes (dentro de [MonthMileage]).
class MonthUsage {
  const MonthUsage({required this.userId, required this.used});

  final int userId;
  final double used;

  factory MonthUsage.fromJson(JsonMap json) =>
      MonthUsage(userId: jInt(json['userId']), used: jDouble(json['used']));

  JsonMap toJson() => {'userId': userId, 'used': used};
}

/// Uso vs aconsejado de un mes concreto (barra/carrusel mensual).
class MonthMileage {
  const MonthMileage({
    required this.month,
    required this.recommendedPerPerson,
    required this.perUser,
  });

  /// Mes `YYYY-MM`.
  final String month;

  /// Km aconsejados por persona ese mes (prorrateado a hoy si es el mes en curso).
  final double recommendedPerPerson;

  /// Km usados por persona ese mes.
  final List<MonthUsage> perUser;

  /// Km usados por `userId` ese mes (0 si no consta).
  double usedFor(int userId) {
    for (final u in perUser) {
      if (u.userId == userId) return u.used;
    }
    return 0;
  }

  factory MonthMileage.fromJson(JsonMap json) => MonthMileage(
    month: jStr(json['month']),
    recommendedPerPerson: jDouble(json['recommendedPerPerson']),
    perUser: asMapList(json['perUser']).map(MonthUsage.fromJson).toList(),
  );

  JsonMap toJson() => {
    'month': month,
    'recommendedPerPerson': recommendedPerPerson,
    'perUser': perUser.map((u) => u.toJson()).toList(),
  };
}

/// Agregado de km (Fase F6). `GET /api/mileage`.
class MileageSummary {
  const MileageSummary({
    required this.people,
    required this.annualKmTotal,
    required this.annualKmPerPerson,
    required this.sharedKm,
    required this.sharedKmPerPerson,
    this.kmStartDate,
    this.monthlyKmPerPerson = 0,
    this.dailyKmPerPerson = 0,
    this.recommendedYearToDate = 0,
    this.months = const [],
  });

  /// Una entrada por persona (Andy y Dennis).
  final List<PersonMileage> people;

  /// Total anual (15.000) y cupo por persona (7.500).
  final int annualKmTotal;
  final int annualKmPerPerson;

  /// Km compartidos del año (total) y la parte que asume cada persona (50/50).
  final double sharedKm;
  final double sharedKmPerPerson;

  /// Fecha del primer uso (inicio del cómputo); `null` si no hay usos.
  final String? kmStartDate;

  /// Cupo aconsejado por persona: mensual (= anual/12) y diario (referencia).
  final int monthlyKmPerPerson;
  final double dailyKmPerPerson;

  /// Km aconsejados por persona ACUMULADOS en el año en curso hasta hoy (barra anual).
  final double recommendedYearToDate;

  /// Uso vs aconsejado de cada mes registrado (barra mensual / carrusel).
  final List<MonthMileage> months;

  factory MileageSummary.fromJson(JsonMap json) => MileageSummary(
    people: asMapList(json['perUser']).map(PersonMileage.fromJson).toList(),
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    sharedKm: jDouble(json['sharedKm']),
    sharedKmPerPerson: jDouble(json['sharedKmPerPerson']),
    kmStartDate: jStrOrNull(json['kmStartDate']),
    monthlyKmPerPerson: jIntOrNull(json['monthlyKmPerPerson']) ?? 0,
    dailyKmPerPerson: jDoubleOrNull(json['dailyKmPerPerson']) ?? 0,
    recommendedYearToDate: jDoubleOrNull(json['recommendedYearToDate']) ?? 0,
    months: json['months'] == null
        ? const []
        : asMapList(json['months']).map(MonthMileage.fromJson).toList(),
  );

  JsonMap toJson() => {
    'perUser': people.map((p) => p.toJson()).toList(),
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'sharedKm': sharedKm,
    'sharedKmPerPerson': sharedKmPerPerson,
    'kmStartDate': kmStartDate,
    'monthlyKmPerPerson': monthlyKmPerPerson,
    'dailyKmPerPerson': dailyKmPerPerson,
    'recommendedYearToDate': recommendedYearToDate,
    'months': months.map((m) => m.toJson()).toList(),
  };
}
