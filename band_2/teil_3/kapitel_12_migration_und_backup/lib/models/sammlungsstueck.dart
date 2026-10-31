class Sammlungsstueck {
  final int? id;
  final String titel;
  final String kategorie;
  final double schaetzwert;
  final double kaufpreis;
  final String zustand;

  const Sammlungsstueck({
    this.id,
    required this.titel,
    required this.kategorie,
    required this.schaetzwert,
    this.kaufpreis = 0.0,
    this.zustand = 'Gut',
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titel': titel,
      'kategorie': kategorie,
      'schaetzwert': schaetzwert,
      'kaufpreis': kaufpreis,
      'zustand': zustand,
    };
  }

  factory Sammlungsstueck.fromMap(Map<String, Object?> map) {
    return Sammlungsstueck(
      id: map['id'] as int?,
      titel: map['titel'] as String,
      kategorie: map['kategorie'] as String,
      schaetzwert: (map['schaetzwert'] as num).toDouble(),
      kaufpreis: ((map['kaufpreis'] as num?) ?? 0.0).toDouble(),
      zustand: (map['zustand'] as String?) ?? 'Gut',
    );
  }

  Sammlungsstueck copyWith({
    int? id,
    String? titel,
    String? kategorie,
    double? schaetzwert,
    double? kaufpreis,
    String? zustand,
  }) {
    return Sammlungsstueck(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      kategorie: kategorie ?? this.kategorie,
      schaetzwert: schaetzwert ?? this.schaetzwert,
      kaufpreis: kaufpreis ?? this.kaufpreis,
      zustand: zustand ?? this.zustand,
    );
  }
}
