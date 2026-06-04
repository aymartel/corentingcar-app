/// Tipo de registro de uso / repostaje (Fase F2). Contrato:
/// `'individual' | 'shared'` (compartido se reparte 50/50).
enum EntryType {
  individual,
  shared;

  static EntryType fromJson(String value) => EntryType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => throw ArgumentError('EntryType desconocido: "$value"'),
  );

  String toJson() => name;

  bool get isShared => this == EntryType.shared;
}
