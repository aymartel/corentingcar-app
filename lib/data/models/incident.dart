import 'entry_type.dart';
import 'json_utils.dart';
import 'user.dart';

/// Tipo de incidencia. Tolerante a valores desconocidos (cae a [other]) para que un backend
/// más nuevo no rompa una app ya instalada.
enum IncidentKind {
  fine,
  damage,
  breakdown,
  other;

  static IncidentKind fromJson(String value) => IncidentKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => IncidentKind.other,
  );

  String toJson() => name;

  /// Etiqueta para la UI (en español).
  String get label => switch (this) {
    IncidentKind.fine => 'Multa',
    IncidentKind.damage => 'Golpe',
    IncidentKind.breakdown => 'Avería',
    IncidentKind.other => 'Otro',
  };
}

/// Estado de la incidencia. Resuelta = ya se pagó o ya se reparó.
enum IncidentStatus {
  open,
  resolved;

  static IncidentStatus fromJson(String value) => IncidentStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => IncidentStatus.open,
  );

  String toJson() => name;

  bool get isOpen => this == IncidentStatus.open;
}

/// Incidencia del coche (multa, golpe, avería…). `GET /api/incidents`.
///
/// El importe es opcional: se puede registrar el día que pasa y ponerle el coste después. Solo
/// entra en el saldo al marcarla resuelta, a nombre de [paidBy].
class Incident {
  const Incident({
    required this.id,
    required this.date,
    required this.kind,
    required this.description,
    required this.type,
    required this.status,
    required this.reportedBy,
    this.amountEur,
    this.responsible,
    this.paidBy,
    this.resolvedAt,
    this.createdAt,
  });

  final int id;

  /// Fecha en la que ocurrió (`YYYY-MM-DD`).
  final String date;
  final IncidentKind kind;
  final String description;

  /// Coste previsto (si está abierta) o final (si está resuelta). `null` mientras no se sabe.
  final double? amountEur;

  /// Reparto del coste: compartido 50/50 o individual (lo asume [responsible]).
  final EntryType type;
  final IncidentStatus status;

  /// Quién la registró.
  final User reportedBy;

  /// Quién ASUME el coste si el reparto es individual.
  final User? responsible;

  /// Quién PUSO el dinero (solo cuando está resuelta con importe).
  final User? paidBy;
  final String? resolvedAt;
  final String? createdAt;

  bool get isOpen => status.isOpen;

  factory Incident.fromJson(JsonMap json) => Incident(
    id: jInt(json['id']),
    date: jStr(json['date']),
    kind: IncidentKind.fromJson(jStr(json['kind'])),
    description: jStr(json['description']),
    amountEur: jDoubleOrNull(json['amountEur']),
    type: EntryType.fromJson(jStr(json['type'])),
    status: IncidentStatus.fromJson(jStr(json['status'])),
    reportedBy: User.fromJson(asMap(json['reportedBy'])),
    responsible: json['responsible'] == null
        ? null
        : User.fromJson(asMap(json['responsible'])),
    paidBy: json['paidBy'] == null ? null : User.fromJson(asMap(json['paidBy'])),
    resolvedAt: jStrOrNull(json['resolvedAt']),
    createdAt: jStrOrNull(json['createdAt']),
  );

  JsonMap toJson() => {
    'id': id,
    'date': date,
    'kind': kind.toJson(),
    'description': description,
    'amountEur': amountEur,
    'type': type.toJson(),
    'status': status.toJson(),
    'reportedBy': reportedBy.toJson(),
    'responsible': responsible?.toJson(),
    'paidBy': paidBy?.toJson(),
    'resolvedAt': resolvedAt,
    'createdAt': createdAt,
  };
}
