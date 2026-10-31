class Kassette {
  final int? id;
  final String titel;
  final String bandtyp;
  final int farbcode;
  final String wavPfad;
  final int dauerSekunden;

  const Kassette({
    this.id,
    required this.titel,
    required this.bandtyp,
    required this.farbcode,
    required this.wavPfad,
    this.dauerSekunden = 180,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titel': titel,
      'bandtyp': bandtyp,
      'farbcode': farbcode,
      'wav_pfad': wavPfad,
      'dauer_sekunden': dauerSekunden,
    };
  }

  factory Kassette.fromMap(Map<String, Object?> map) {
    return Kassette(
      id: map['id'] as int?,
      titel: map['titel'] as String,
      bandtyp: map['bandtyp'] as String,
      farbcode: map['farbcode'] as int,
      wavPfad: map['wav_pfad'] as String,
      dauerSekunden: (map['dauer_sekunden'] as int?) ?? 180,
    );
  }
}
