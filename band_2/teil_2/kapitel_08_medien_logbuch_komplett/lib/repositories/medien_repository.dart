import '../models/medium.dart';

abstract class MedienRepository {
  Future<List<Medium>> ladeAlle();
  Future<void> speichere(List<Medium> medien);
}

class LokalesSpeicherRepository implements MedienRepository {
  List<Medium> _speicher = const [
    Medium(
      id: '1',
      titel: 'Die Rust-Werkstatt (Band 1)',
      ersteller: 'Volker Dähn',
      typ: MedienTyp.buch,
      seitenOderMinuten: 380,
      sterne: 5,
      istFavorit: true,
    ),
    Medium(
      id: '2',
      titel: 'Clean Code Handwerk',
      ersteller: 'Robert C. Martin',
      typ: MedienTyp.buch,
      seitenOderMinuten: 460,
      sterne: 4,
      istFavorit: false,
    ),
    Medium(
      id: '3',
      titel: 'Der Marsianer',
      ersteller: 'Andy Weir',
      typ: MedienTyp.buch,
      seitenOderMinuten: 420,
      sterne: 5,
      istFavorit: true,
    ),
  ];

  @override
  Future<List<Medium>> ladeAlle() async {
    return List.from(_speicher);
  }

  @override
  Future<void> speichere(List<Medium> medien) async {
    _speicher = List.from(medien);
  }
}
