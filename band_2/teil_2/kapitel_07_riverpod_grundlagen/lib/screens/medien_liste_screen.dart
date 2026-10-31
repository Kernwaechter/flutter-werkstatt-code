import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medium.dart';
import '../providers/medien_provider.dart';

class MedienListeScreen extends ConsumerWidget {
  const MedienListeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Medium> medien = ref.watch(medienProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: Text('Riverpod Logbuch (${medien.length})'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medien.length,
        itemBuilder: (context, index) {
          final item = medien[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                item.titel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${item.ersteller} · ${item.seitenOderMinuten} S.',
              ),
              trailing: IconButton(
                icon: Icon(
                  item.istFavorit
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: item.istFavorit ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  ref
                      .read(medienProvider.notifier)
                      .favoritUmschalten(item.id);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(medienProvider.notifier).hinzufuegen(
                Medium(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  titel: 'Neues Buch #${medien.length + 1}',
                  ersteller: 'Unbekannt',
                  typ: MedienTyp.buch,
                  seitenOderMinuten: 300,
                  sterne: 5,
                  istFavorit: false,
                ),
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
