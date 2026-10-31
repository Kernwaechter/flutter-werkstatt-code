enum MedienTyp { buch, spiel, podcast }

class Medium {
  final String id;
  final String titel;
  final String ersteller;
  final MedienTyp typ;
  final int seitenOderMinuten;
  final int sterne;
  final bool istFavorit;

  const Medium({
    required this.id,
    required this.titel,
    required this.ersteller,
    required this.typ,
    required this.seitenOderMinuten,
    required this.sterne,
    this.istFavorit = false,
  });

  Medium copyWith({
    String? titel,
    String? ersteller,
    MedienTyp? typ,
    int? seitenOderMinuten,
    int? sterne,
    bool? istFavorit,
  }) {
    return Medium(
      id: id,
      titel: titel ?? this.titel,
      ersteller: ersteller ?? this.ersteller,
      typ: typ ?? this.typ,
      seitenOderMinuten: seitenOderMinuten ?? this.seitenOderMinuten,
      sterne: sterne ?? this.sterne,
      istFavorit: istFavorit ?? this.istFavorit,
    );
  }
}
