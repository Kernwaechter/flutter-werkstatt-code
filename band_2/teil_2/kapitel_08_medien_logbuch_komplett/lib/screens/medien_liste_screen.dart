import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medium.dart';
import '../providers/medien_provider.dart';
import '../providers/abgeleitete_provider.dart';

class MedienListeScreen extends ConsumerStatefulWidget {
  const MedienListeScreen({super.key});

  @override
  ConsumerState<MedienListeScreen> createState() =>
      _MedienListeScreenState();
}

class _MedienListeScreenState extends ConsumerState<MedienListeScreen> {
  late final TextEditing_suchController = TextEditingController();

  @override
  void dispose() {
    _suchController.dispose();
    super.dispose();
  }

  late final TextEditingController _suchController;

  @override
  void initState() {
    super.initState();
    _suchController = TextEditingController();
  }

  void _zeigeNeuesMediumDialog(BuildContext context) {
    final titelController = TextEditingController();
    final erstellerController = TextEditingController();
    final umfangController = TextEditingController(text: '250');
    MedienTyp gewaehlterTyp = MedienTyp.buch;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Neuen Eintrag erfassen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titelController,
                      decoration: const InputDecoration(
                        labelText: 'Titel',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: erstellerController,
                      decoration: const InputDecoration(
                        labelText: 'Autor / Ersteller',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: umfangController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seiten bzw. Minuten',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MedienTyp>(
                      initialValue: gewaehlterTyp,
                      decoration: const InputDecoration(
                        labelText: 'Medientyp',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: MedienTyp.buch,
                          child: Text('Buch'),
                        ),
                        DropdownMenuItem(
                          value: MedienTyp.spiel,
                          child: Text('Spiel'),
                        ),
                        DropdownMenuItem(
                          value: MedienTyp.podcast,
                          child: Text('Podcast'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => gewaehlterTyp = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () {
                    final titel = titelController.text.trim();
                    if (titel.isEmpty) return;
                    final ersteller = erstellerController.text.trim();
                    final umfang =
                        int.tryParse(umfangController.text) ?? 100;

                    ref.read(medienProvider.notifier).hinzufuegen(
                          Medium(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            titel: titel,
                            ersteller:
                                ersteller.isEmpty ? 'Autor' : ersteller,
                            typ: gewaehlterTyp,
                            seitenOderMinuten: umfang,
                            sterne: 5,
                            istFavorit: false,
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medien = ref.watch(gefilterteMedienProvider);
    final stats = ref.watch(statistikProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text('Medien-Logbuch (Riverpod)'),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _suchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Titel oder Autor suchen...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _suchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white70),
                            onPressed: () {
                              _suchController.clear();
                              ref
                                  .read(suchbegriffProvider.notifier)
                                  .state = '';
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF334155),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (text) {
                    ref.read(suchbegriffProvider.notifier).state = text;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatistikChip(
                      label: 'Gesamt',
                      wert: '${stats['gesamt'] ?? 0}',
                      farbe: const Color(0xFF38BDF8),
                    ),
                    _StatistikChip(
                      label: 'Umfang',
                      wert: '${stats['seiten'] ?? 0} S.',
                      farbe: const Color(0xFF4ADE80),
                    ),
                    _StatistikChip(
                      label: 'Favoriten',
                      wert: '${stats['favoriten'] ?? 0}',
                      farbe: const Color(0xFFF472B6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: medien.isEmpty
                ? const Center(
                    child: Text(
                      'Keine passenden Einträge gefunden.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: medien.length,
                    itemBuilder: (context, index) {
                      final item = medien[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE2E8F0),
                            child: Icon(
                              item.typ == MedienTyp.buch
                                  ? Icons.book
                                  : item.typ == MedienTyp.spiel
                                      ? Icons.videogame_asset
                                      : Icons.podcasts,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          title: Text(
                            item.titel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${item.ersteller} · ${item.seitenOderMinuten} ${item.typ == MedienTyp.podcast ? "Min." : "Seiten"}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(
                                  5,
                                  (starIndex) => Icon(
                                    starIndex < item.sterne
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  item.istFavorit
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: item.istFavorit
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  ref
                                      .read(medienProvider.notifier)
                                      .favoritUmschalten(item.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  ref
                                      .read(medienProvider.notifier)
                                      .loeschen(item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _zeigeNeuesMediumDialog(context),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Eintrag erfassen'),
      ),
    );
  }
}

class _StatistikChip extends StatelessWidget {
  final String label;
  final String wert;
  final Color farbe;

  const _StatistikChip({
    required this.label,
    required this.wert,
    required this.farbe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            wert,
            style: TextStyle(
              color: farbe,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
