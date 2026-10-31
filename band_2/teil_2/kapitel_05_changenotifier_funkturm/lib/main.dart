import 'package:flutter/material.dart';
import 'controllers/medien_controller.dart';
import 'models/medium.dart';

void main() {
  runApp(const MedienLogbuchApp());
}

final MedienController globalerController = MedienController();

class MedienLogbuchApp extends StatelessWidget {
  const MedienLogbuchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medien-Logbuch',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const MedienUebersichtScreen(),
    );
  }
}

class MedienUebersichtScreen extends StatelessWidget {
  const MedienUebersichtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text('Medien-Logbuch · Kapitel 5'),
      ),
      body: ListenableBuilder(
        listenable: globalerController,
        builder: (context, child) {
          final controller = globalerController;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFFFFFFF),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoBadge(
                      label: 'Einträge',
                      wert: '${controller.anzahlGesamt}',
                      farbe: const Color(0xFF0284C7),
                    ),
                    _InfoBadge(
                      label: 'Umfang',
                      wert: '${controller.summeSeitenOderMinuten}',
                      farbe: const Color(0xFF059669),
                    ),
                    _InfoBadge(
                      label: 'Favoriten',
                      wert: '${controller.anzahlFavoriten}',
                      farbe: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.medien.length,
                  itemBuilder: (context, index) {
                    final item = controller.medien[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF0F172A).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFF0F172A),
                          child: Icon(
                            item.typ == MedienTyp.buch
                                ? Icons.menu_book
                                : item.typ == MedienTyp.spiel
                                    ? Icons.sports_esports
                                    : Icons.podcasts,
                          ),
                        ),
                        title: Text(
                          item.titel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item.ersteller} · ${item.seitenOderMinuten} '
                          '${item.typ == MedienTyp.podcast ? "Min." : "S."}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '★' * item.sterne,
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                item.istFavorit
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: item.istFavorit
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                controller.favoritUmschalten(item.id);
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        onPressed: () {
          globalerController.mediumHinzufuegen(
            Medium(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              titel: 'Neu entdeckt #${globalerController.anzahlGesamt + 1}',
              ersteller: 'Unbekannt',
              typ: MedienTyp.buch,
              seitenOderMinuten: 250,
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

class _InfoBadge extends StatelessWidget {
  final String label;
  final String wert;
  final Color farbe;

  const _InfoBadge({
    required this.label,
    required this.wert,
    required this.farbe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          wert,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: farbe,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
