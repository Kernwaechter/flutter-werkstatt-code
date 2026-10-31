import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medium.dart';
import 'medien_provider.dart';

final suchbegriffProvider = StateProvider<String>((ref) => '');

final gefilterteMedienProvider = Provider<List<Medium>>((ref) {
  final alle = ref.watch(medienProvider);
  final suche = ref.watch(suchbegriffProvider).trim().toLowerCase();

  if (suche.isEmpty) return alle;

  return alle.where((m) {
    return m.titel.toLowerCase().contains(suche) ||
        m.ersteller.toLowerCase().contains(suche);
  }).toList();
});

final statistikProvider = Provider<Map<String, int>>((ref) {
  final alle = ref.watch(medienProvider);
  int seiten = 0;
  for (final m in alle) {
    seiten += m.seitenOderMinuten;
  }
  return {
    'gesamt': alle.length,
    'seiten': seiten,
    'favoriten': alle.where((m) => m.istFavorit).length,
  };
});
