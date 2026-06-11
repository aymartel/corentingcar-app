import 'entry_type.dart';
import 'json_utils.dart';
import 'user.dart';

/// Tipo de cambio propuesto sobre un uso.
enum UsageChangeKind {
  create,
  update,
  delete;

  static UsageChangeKind fromJson(String value) =>
      UsageChangeKind.values.firstWhere(
        (k) => k.name == value,
        orElse: () => throw ArgumentError('UsageChangeKind desconocido: "$value"'),
      );

  String toJson() => name;
}

/// Estado de un cambio de uso. Misma máquina de estados que las solicitudes.
enum UsageChangeStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static UsageChangeStatus fromJson(String value) =>
      UsageChangeStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => throw ArgumentError('UsageChangeStatus desconocido: "$value"'),
      );

  String toJson() => name;

  bool get isPending => this == UsageChangeStatus.pending;
}

/// Conjunto de campos de un uso (propuesto u original). Distancias en km.
class UsageChangeFields {
  const UsageChangeFields({
    required this.userId,
    required this.date,
    required this.startKm,
    required this.endKm,
    required this.type,
  });

  final int userId;
  final String date;
  final int startKm;
  final int endKm;
  final EntryType type;

  int get totalKm => endKm - startKm;

  factory UsageChangeFields.fromJson(JsonMap json) => UsageChangeFields(
    userId: jInt(json['userId']),
    date: jStr(json['date']),
    startKm: jInt(json['startKm']),
    endKm: jInt(json['endKm']),
    type: EntryType.fromJson(jStr(json['type'])),
  );

  JsonMap toJson() => {
    'userId': userId,
    'date': date,
    'startKm': startKm,
    'endKm': endKm,
    'type': type.toJson(),
  };
}

/// Cambio de uso pendiente de aprobación del otro usuario ("historial de usos").
/// `GET/POST/PATCH /api/usage/changes`.
class UsageChange {
  const UsageChange({
    required this.id,
    required this.kind,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    this.usageId,
    this.proposed,
    this.original,
    this.reason,
    this.createdAt,
    this.resolvedAt,
    this.requester,
    this.recipient,
  });

  final int id;
  final UsageChangeKind kind;
  final int requesterId;
  final int recipientId;
  final UsageChangeStatus status;

  /// Uso afectado (update/delete). `null` para `create`.
  final int? usageId;

  /// Valores propuestos. `null` para `delete`.
  final UsageChangeFields? proposed;

  /// Snapshot de los valores previos. `null` para `create`.
  final UsageChangeFields? original;

  final String? reason;
  final String? createdAt;
  final String? resolvedAt;

  /// Usuarios anidados (el backend los incluye en las listas).
  final User? requester;
  final User? recipient;

  factory UsageChange.fromJson(JsonMap json) => UsageChange(
    id: jInt(json['id']),
    kind: UsageChangeKind.fromJson(jStr(json['kind'])),
    requesterId: jInt(json['requesterId']),
    recipientId: jInt(json['recipientId']),
    status: UsageChangeStatus.fromJson(jStr(json['status'])),
    usageId: jIntOrNull(json['usageId']),
    proposed: json['proposed'] == null
        ? null
        : UsageChangeFields.fromJson(asMap(json['proposed'])),
    original: json['original'] == null
        ? null
        : UsageChangeFields.fromJson(asMap(json['original'])),
    reason: jStrOrNull(json['reason']),
    createdAt: jStrOrNull(json['createdAt']),
    resolvedAt: jStrOrNull(json['resolvedAt']),
    requester: json['requester'] == null
        ? null
        : User.fromJson(asMap(json['requester'])),
    recipient: json['recipient'] == null
        ? null
        : User.fromJson(asMap(json['recipient'])),
  );

  JsonMap toJson() => {
    'id': id,
    'kind': kind.toJson(),
    'requesterId': requesterId,
    'recipientId': recipientId,
    'status': status.toJson(),
    'usageId': usageId,
    'proposed': proposed?.toJson(),
    'original': original?.toJson(),
    'reason': reason,
    'createdAt': createdAt,
    'resolvedAt': resolvedAt,
    'requester': requester?.toJson(),
    'recipient': recipient?.toJson(),
  };
}
