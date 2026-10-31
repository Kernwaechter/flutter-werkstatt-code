import 'package:flutter/material.dart';
import 'controllers/medien_controller.dart';
import 'models/medium.dart';
import 'screens/statistik_screen.dart';

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
        title: const Text('Medien-Logbuch · Kapitel 6'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StatistikScreen(controller: globalerController),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: globalerController,
        builder: (context, child) {
          final controller = globalerController;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.medien.length,
            itemBuilder: (context, index) {
              final item = controller.medien[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                  subtitle: Text('${item.ersteller} · ${item.seitenOderMinuten} S.'),
                  trailing: IconButton(
                    icon: Icon(
                      item.istFavorit ? Icons.favorite : Icons.favorite_border,
                      color: item.istFavorit ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      controller.favoritUmschalten(item.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
