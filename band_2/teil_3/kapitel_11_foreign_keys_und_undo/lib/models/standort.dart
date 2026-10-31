class Standort {
  final int? id;
  final String name;
  final String beschreibung;

  const Standort({
    this.id,
    required this.name,
    this.beschreibung = '',
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'beschreibung': beschreibung,
    };
  }

  factory Standort.fromMap(Map<String, Object?> map) {
    return Standort(
      id: map['id'] as int?,
      name: map['name'] as String,
      beschreibung: (map['beschreibung'] as String?) ?? '',
    );
  }
}
