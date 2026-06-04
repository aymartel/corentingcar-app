/// Estado de una solicitud de uso (Fase F2). Mapea **exactamente** los valores
/// del contrato: `'pending' | 'accepted' | 'rejected' | 'cancelled'`.
enum RequestStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  static RequestStatus fromJson(String value) =>
      RequestStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () =>
            throw ArgumentError('RequestStatus desconocido: "$value"'),
      );

  String toJson() => name;

  bool get isPending => this == RequestStatus.pending;
}
