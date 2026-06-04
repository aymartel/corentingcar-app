import 'json_utils.dart';
import 'request_status.dart';
import 'user.dart';

/// Solicitud de uso del coche (Fase F8). `GET/POST/PATCH /api/requests`.
/// Máquina de estados: `pending → accepted|rejected|cancelled`.
class UseRequest {
  const UseRequest({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.useDate,
    required this.status,
    this.message,
    this.createdAt,
    this.resolvedAt,
    this.requester,
    this.recipient,
  });

  final int id;

  /// Quién pide (no tiene prioridad ese día).
  final int requesterId;

  /// Quién tiene prioridad y acepta/rechaza.
  final int recipientId;

  /// Día para el que se pide, ISO `YYYY-MM-DD`.
  final String useDate;
  final RequestStatus status;

  /// Nota opcional del solicitante.
  final String? message;
  final String? createdAt;

  /// Se fija al salir de `pending`.
  final String? resolvedAt;

  /// Usuarios anidados (el backend los incluye en las listas).
  final User? requester;
  final User? recipient;

  factory UseRequest.fromJson(JsonMap json) => UseRequest(
    id: jInt(json['id']),
    requesterId: jInt(json['requesterId']),
    recipientId: jInt(json['recipientId']),
    useDate: jStr(json['useDate']),
    status: RequestStatus.fromJson(jStr(json['status'])),
    message: jStrOrNull(json['message']),
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
    'requesterId': requesterId,
    'recipientId': recipientId,
    'useDate': useDate,
    'status': status.toJson(),
    'message': message,
    'createdAt': createdAt,
    'resolvedAt': resolvedAt,
    'requester': requester?.toJson(),
    'recipient': recipient?.toJson(),
  };
}
