import 'snack.dart';

class BestellPosition {
  final Snack snack;
  final bool istXl;
  final List<String> extras;
  final int anzahl;

  const BestellPosition({
    required this.snack,
    required this.istXl,
    required this.extras,
    required this.anzahl,
  });

  double get einzelpreis {
    double preis = snack.grundpreis;
    if (istXl) {
      preis += 1.20;
    }
    preis += extras.length * 0.60;
    return preis;
  }

  double get gesamtpreis => einzelpreis * anzahl;

  String get zusammenfassung {
    final List<String> teile = [
      istXl ? 'Groesse XL' : 'Standard',
      ...extras,
    ];
    return teile.join(' · ');
  }
}
