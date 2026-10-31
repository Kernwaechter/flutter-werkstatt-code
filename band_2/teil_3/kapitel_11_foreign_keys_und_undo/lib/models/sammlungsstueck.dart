class Sammlungsstueck {
  final int? id;
  final String titel;
  final String kategorie;
  final double schaetzwert;
  final String zustand;
  final int? standortId;
  final String? standortName;

  const Sammlungsstueck({
    this.id,
    required this.titel,
    required this.kategorie,
    required this.schaetzwert,
    this.zustand = 'Gut',
    this.standortId,
    this.standortName,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titel': titel,
      'kategorie': kategorie,
      'schaetzwert': schaetzwert,
      'zustand': zustand,
      'standort_id': standortId,
    };
  }

  factory Sammlungsstueck.fromMap(Map<String, Object?> map) {
    return Sammlungsstueck(
      id: map['id'] as int?,
      titel: map['titel'] as String,
      kategorie: map['kategorie'] as String,
      schaetzwert: (map['schaetzwert'] as num).toDouble(),
      zustand: (map['zustand'] as String?) ?? 'Gut',
      standortId: map['standort_id'] as int?,
      standortName: map['standort_name'] as String?,
    );
  }

  Sammlungsstueck copyWith({
    int? id,
    String? titel,
    String? kategorie,
    double? schaetzwert,
    String? zustand,
    int? standortId,
    String? standortName,
  }) {
    return Sammlungsstueck(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      kategorie: kategorie ?? this.kategorie,
      schaetzwert: schaetzwert ?? this.schaetzwert,
      zustand: zustand ?? this.zustand,
      standortId: standortId ?? this.standortId,
      standortName: standortName ?? this.standortName,
    );
  }
}
