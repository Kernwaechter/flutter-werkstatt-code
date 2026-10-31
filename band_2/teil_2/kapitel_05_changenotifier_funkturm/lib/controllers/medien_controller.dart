import 'package:flutter/foundation.dart';
import '../models/medium.dart';

class MedienController extends ChangeNotifier {
  final List<Medium> _medien = [
    const Medium(
      id: '1',
      titel: 'Die Rust-Werkstatt (Band 1)',
      ersteller: 'Volker Dähn',
      typ: MedienTyp.buch,
      seitenOderMinuten: 380,
      sterne: 5,
      istFavorit: true,
    ),
    const Medium(
      id: '2',
      titel: 'Der Marsianer',
      ersteller: 'Andy Weir',
      typ: MedienTyp.buch,
      seitenOderMinuten: 420,
      sterne: 4,
      istFavorit: false,
    ),
    const Medium(
      id: '3',
      titel: 'Security Now Podcast',
      ersteller: 'Steve Gibson',
      typ: MedienTyp.podcast,
      seitenOderMinuten: 120,
      sterne: 5,
      istFavorit: true,
    ),
  ];

  List<Medium> get medien => List.unmodifiable(_medien);

  int get anzahlGesamt => _medien.length;

  int get summeSeitenOderMinuten {
    int summe = 0;
    for (final m in _medien) {
      summe += m.seitenOderMinuten;
    }
    return summe;
  }

  int get anzahlFavoriten {
    return _medien.where((m) => m.istFavorit).length;
  }

  void mediumHinzufuegen(Medium neu) {
    _medien.insert(0, neu);
    notifyListeners();
  }

  void favoritUmschalten(String id) {
    final index = _medien.indexWhere((m) => m.id == id);
    if (index != -1) {
      final alt = _medien[index];
      _medien[index] = alt.copyWith(istFavorit: !alt.istFavorit);
      notifyListeners();
    }
  }

  void bewertungAendern(String id, int neueSterne) {
    final index = _medien.indexWhere((m) => m.id == id);
    if (index != -1) {
      final alt = _medien[index];
      _medien[index] = alt.copyWith(sterne: neueSterne);
      notifyListeners();
    }
  }

  void mediumLoeschen(String id) {
    _medien.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
