class Sammlungsstueck {
  final int? id;
  final String titel;
  final String kategorie;
  final double schaetzwert;

  const Sammlungsstueck({
    this.id,
    required this.titel,
    required this.kategorie,
    required this.schaetzwert,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titel': titel,
      'kategorie': kategorie,
      'schaetzwert': schaetzwert,
    };
  }

  factory Sammlungsstueck.fromMap(Map<String, Object?> map) {
    return Sammlungsstueck(
      id: map['id'] as int?,
      titel: map['titel'] as String,
      kategorie: map['kategorie'] as String,
      schaetzwert: (map['schaetzwert'] as num).toDouble(),
    );
  }
}
