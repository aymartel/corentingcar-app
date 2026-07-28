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
    this.budgetPerPerson = 0,
  });

  /// Mes `YYYY-MM`.
  final String month;

  /// Km aconsejados por persona ese mes (prorrateado a hoy si es el mes en curso).
  final double recommendedPerPerson;

  /// Cupo COMPLETO por persona de ese mes, según el plan vigente entonces (625 con 15.000,
  /// 1.041,67 con 25.000). Es la escala de la barra mensual. 0 si el backend no lo envía.
  final double budgetPerPerson;

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
    budgetPerPerson: jDoubleOrNull(json['budgetPerPerson']) ?? 0,
    perUser: asMapList(json['perUser']).map(MonthUsage.fromJson).toList(),
  );

  JsonMap toJson() => {
    'month': month,
    'recommendedPerPerson': recommendedPerPerson,
    'budgetPerPerson': budgetPerPerson,
    'perUser': perUser.map((u) => u.toJson()).toList(),
  };
}

/// Tramo del año con un plan de kilometraje distinto (para explicar un cupo anual mixto).
class YearPlanSegment {
  const YearPlanSegment({
    required this.fromMonth,
    required this.toMonth,
    required this.annualKmTotal,
  });

  /// Mes inicial y final del tramo (1..12).
  final int fromMonth;
  final int toMonth;
  final int annualKmTotal;

  factory YearPlanSegment.fromJson(JsonMap json) => YearPlanSegment(
    fromMonth: jInt(json['fromMonth']),
    toMonth: jInt(json['toMonth']),
    annualKmTotal: jInt(json['annualKmTotal']),
  );

  JsonMap toJson() => {
    'fromMonth': fromMonth,
    'toMonth': toMonth,
    'annualKmTotal': annualKmTotal,
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
    this.windowStart,
    this.kmStartDate,
    this.monthlyKmPerPerson = 0,
    this.currentMonthKmTotal = 0,
    this.currentMonthKmPerPerson = 0,
    this.dailyKmPerPerson = 0,
    this.recommendedYearToDate = 0,
    this.months = const [],
    this.yearPlanSegments = const [],
  });

  /// Una entrada por persona (Andy y Dennis).
  final List<PersonMileage> people;

  /// Cupo EFECTIVO del año natural en curso, que puede ser mixto si el plan cambió a mitad de
  /// año (2026 con subida a 25.000 en agosto → 9.583 por persona y 19.166 en total). El NOMINAL
  /// del plan contratado (25.000 km/año) está en [Rules.annualKmTotal].
  final int annualKmTotal;
  final int annualKmPerPerson;

  /// Km compartidos del año (total) y la parte que asume cada persona (50/50).
  final double sharedKm;
  final double sharedKmPerPerson;

  /// Primer día de la ventana de cómputo (`YYYY-01-01` con el año natural).
  final String? windowStart;

  /// Año de la ventana en curso; el año actual si el backend no manda la ventana.
  String get windowYear =>
      windowStart != null && windowStart!.length >= 4
      ? windowStart!.substring(0, 4)
      : '${DateTime.now().year}';

  /// Fecha del primer uso (inicio del cómputo); `null` si no hay usos.
  final String? kmStartDate;

  /// Cupo mensual por persona del mes en curso, redondeado a entero (compatibilidad).
  final int monthlyKmPerPerson;

  /// Cupo del mes en curso de los dos juntos = anual / 12 (25.000 → 2.083). Es la cifra que
  /// enseña la app del renting.
  final int currentMonthKmTotal;

  /// Cupo del mes en curso por persona, con decimales (25.000 → 1.041,67).
  final double currentMonthKmPerPerson;
  final double dailyKmPerPerson;

  /// Km aconsejados por persona ACUMULADOS en el año en curso hasta hoy (barra anual).
  final double recommendedYearToDate;

  /// Uso vs aconsejado de cada mes registrado (barra mensual / carrusel).
  final List<MonthMileage> months;

  /// Tramos del año si el plan cambió a mitad (vacío o 1 elemento si fue constante).
  final List<YearPlanSegment> yearPlanSegments;

  factory MileageSummary.fromJson(JsonMap json) => MileageSummary(
    people: asMapList(json['perUser']).map(PersonMileage.fromJson).toList(),
    annualKmTotal: jInt(json['annualKmTotal']),
    annualKmPerPerson: jInt(json['annualKmPerPerson']),
    sharedKm: jDouble(json['sharedKm']),
    sharedKmPerPerson: jDouble(json['sharedKmPerPerson']),
    windowStart: jStrOrNull(json['windowStart']),
    kmStartDate: jStrOrNull(json['kmStartDate']),
    monthlyKmPerPerson: jIntOrNull(json['monthlyKmPerPerson']) ?? 0,
    currentMonthKmTotal: jIntOrNull(json['currentMonthKmTotal']) ?? 0,
    currentMonthKmPerPerson: jDoubleOrNull(json['currentMonthKmPerPerson']) ?? 0,
    dailyKmPerPerson: jDoubleOrNull(json['dailyKmPerPerson']) ?? 0,
    recommendedYearToDate: jDoubleOrNull(json['recommendedYearToDate']) ?? 0,
    months: json['months'] == null
        ? const []
        : asMapList(json['months']).map(MonthMileage.fromJson).toList(),
    yearPlanSegments: json['yearPlanSegments'] == null
        ? const []
        : asMapList(json['yearPlanSegments']).map(YearPlanSegment.fromJson).toList(),
  );

  JsonMap toJson() => {
    'perUser': people.map((p) => p.toJson()).toList(),
    'annualKmTotal': annualKmTotal,
    'annualKmPerPerson': annualKmPerPerson,
    'sharedKm': sharedKm,
    'sharedKmPerPerson': sharedKmPerPerson,
    'windowStart': windowStart,
    'kmStartDate': kmStartDate,
    'monthlyKmPerPerson': monthlyKmPerPerson,
    'currentMonthKmTotal': currentMonthKmTotal,
    'currentMonthKmPerPerson': currentMonthKmPerPerson,
    'dailyKmPerPerson': dailyKmPerPerson,
    'recommendedYearToDate': recommendedYearToDate,
    'months': months.map((m) => m.toJson()).toList(),
    'yearPlanSegments': yearPlanSegments.map((s) => s.toJson()).toList(),
  };
}
