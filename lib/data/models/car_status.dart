import 'json_utils.dart';
import 'user.dart';

/// Disponibilidad **real** del coche ahora mismo (Fase F12). Es independiente
/// de la prioridad del día.
enum CarAvailability {
  free,
  taken;

  static CarAvailability fromJson(String value) =>
      value == 'taken' ? CarAvailability.taken : CarAvailability.free;

  String toJson() => name;
}

/// Los dos parqueos fijos donde se puede dejar el coche: casa de cada persona.
enum ParkingSpot {
  user1,
  user2,
  other;

  static ParkingSpot? fromJsonOrNull(String? value) => switch (value) {
    'user1' => ParkingSpot.user1,
    'user2' => ParkingSpot.user2,
    'other' => ParkingSpot.other,
    _ => null,
  };

  String toJson() => name;
}

/// Estado actual del coche (Fase F12). `GET /api/car-status`.
///
/// `since` llega en **UTC**; aquí se guarda ya **en hora local** (`toLocal()`).
class CarStatus {
  const CarStatus({
    required this.availability,
    this.user,
    this.parking,
    this.parkingUser,
    this.note,
    this.since,
  });

  final CarAvailability availability;

  /// Quién lo tiene (si `taken`) o quién lo dejó (si `free`). Puede ser nulo.
  final User? user;

  /// En casa de qué persona se dejó.
  final ParkingSpot? parking;

  /// Usuario resuelto del [parking] (para mostrar "en casa de {name}").
  final User? parkingUser;

  /// Nota opcional (p. ej. "plaza 12").
  final String? note;

  /// Desde cuándo (en **hora local**); nulo si nunca se ha registrado nada.
  final DateTime? since;

  bool get isFree => availability == CarAvailability.free;
  bool get isTaken => availability == CarAvailability.taken;

  factory CarStatus.fromJson(JsonMap json) => CarStatus(
    availability: CarAvailability.fromJson(jStr(json['status'])),
    user: json['user'] == null ? null : User.fromJson(asMap(json['user'])),
    parking: ParkingSpot.fromJsonOrNull(jStrOrNull(json['parking'])),
    parkingUser: json['parkingUser'] == null
        ? null
        : User.fromJson(asMap(json['parkingUser'])),
    note: jStrOrNull(json['note']),
    since: _localOrNull(jStrOrNull(json['since'])),
  );

  static DateTime? _localOrNull(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso)?.toLocal();
}
