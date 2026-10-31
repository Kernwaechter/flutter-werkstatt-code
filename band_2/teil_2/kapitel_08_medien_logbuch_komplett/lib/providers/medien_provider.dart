import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medium.dart';
import '../repositories/medien_repository.dart';

final repositoryProvider = Provider<MedienRepository>((ref) {
  return LokalesSpeicherRepository();
});

class MedienNotifier extends Notifier<List<Medium>> {
  @override
  List<Medium> build() {
    return [
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
        titel: 'Clean Code Handwerk',
        ersteller: 'Robert C. Martin',
        typ: MedienTyp.buch,
        seitenOderMinuten: 460,
        sterne: 4,
        istFavorit: false,
      ),
      const Medium(
        id: '3',
        titel: 'Der Marsianer',
        ersteller: 'Andy Weir',
        typ: MedienTyp.buch,
        seitenOderMinuten: 420,
        sterne: 5,
        istFavorit: true,
      ),
    ];
  }

  void hinzufuegen(Medium neu) {
    state = [neu, ...state];
  }

  void favoritUmschalten(String id) {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(istFavorit: !m.istFavorit) else m,
    ];
  }

  void loeschen(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final medienProvider =
    NotifierProvider<MedienNotifier, List<Medium>>(() {
  return MedienNotifier();
});
