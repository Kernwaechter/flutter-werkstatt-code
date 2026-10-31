import '../models/medium.dart';

class StatistikService {
  const StatistikService();

  int berechneLesestunden(List<Medium> medien) {
    int gesamtMinuten = 0;
    for (final m in medien) {
      if (m.typ == MedienTyp.buch) {
        gesamtMinuten += m.seitenOderMinuten;
      } else if (m.typ == MedienTyp.podcast) {
        gesamtMinuten += m.seitenOderMinuten;
      }
    }
    return (gesamtMinuten / 60).round();
  }

  double berechneDurchschnittsSterne(List<Medium> medien) {
    if (medien.isEmpty) return 0.0;
    int summe = 0;
    for (final m in medien) {
      summe += m.sterne;
    }
    return summe / medien.length;
  }
}
