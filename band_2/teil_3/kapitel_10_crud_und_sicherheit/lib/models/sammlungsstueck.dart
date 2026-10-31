class Sammlungsstueck {
  final int? id;
  final String titel;
  final String kategorie;
  final double schaetzwert;
  final String zustand;
  final String notiz;

  const Sammlungsstueck({
    this.id,
    required this.titel,
    required this.kategorie,
    required this.schaetzwert,
    this.zustand = 'Gut',
    this.notiz = '',
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titel': titel,
      'kategorie': kategorie,
      'schaetzwert': schaetzwert,
      'zustand': zustand,
      'notiz': notiz,
    };
  }

  factory Sammlungsstueck.fromMap(Map<String, Object?> map) {
    return Sammlungsstueck(
      id: map['id'] as int?,
      titel: map['titel'] as String,
      kategorie: map['kategorie'] as String,
      schaetzwert: (map['schaetzwert'] as num).toDouble(),
      zustand: (map['zustand'] as String?) ?? 'Gut',
      notiz: (map['notiz'] as String?) ?? '',
    );
  }

  Sammlungsstueck copyWith({
    int? id,
    String? titel,
    String? kategorie,
    double? schaetzwert,
    String? zustand,
    String? notiz,
  }) {
    return Sammlungsstueck(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      kategorie: kategorie ?? this.kategorie,
      schaetzwert: schaetzwert ?? this.schaetzwert,
      zustand: zustand ?? this.zustand,
      notiz: notiz ?? this.notiz,
    );
  }
}
