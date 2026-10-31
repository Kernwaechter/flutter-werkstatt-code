import 'package:flutter/material.dart';

void main() {
  runApp(const SchulhelferApp());
}

class Hausaufgabe {
  final String fach;
  final String titel;
  final String frist;
  bool istErledigt;

  Hausaufgabe({
    required this.fach,
    required this.titel,
    required this.frist,
    this.istErledigt = false,
  });
}

class SchulhelferApp extends StatelessWidget {
  const SchulhelferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Schulhelfer 1.0',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const AufgabenSeite(),
    );
  }
}

class AufgabenSeite extends StatefulWidget {
  const AufgabenSeite({super.key});

  @override
  State<AufgabenSeite> createState() => _AufgabenSeiteState();
}

class _AufgabenSeiteState extends State<AufgabenSeite> {
  final List<String> _faecher = [
    'Mathe',
    'Englisch',
    'Deutsch',
    'Physik',
    'Informatik',
    'Geschichte',
  ];

  final List<Hausaufgabe> _aufgaben = [
    Hausaufgabe(
      fach: 'Mathe',
      titel: 'Buch S. 42, Aufgabe 3a bis 3d',
      frist: 'Morgen',
    ),
    Hausaufgabe(
      fach: 'Englisch',
      titel: 'Unit 3: Vokabeln wiederholen',
      frist: 'Donnerstag',
    ),
  ];

  int get _offeneAnzahl =>
      _aufgaben.where((a) => !a.istErledigt).length;

  Color _fachFarbe(String fach) {
    switch (fach) {
      case 'Mathe':
        return const Color(0xFF2563EB);
      case 'Englisch':
        return const Color(0xFF0D9488);
      case 'Informatik':
        return const Color(0xFF7C3AED);
      case 'Physik':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  void _oeffneEingabeBlatt() {
    final titelController = TextEditingController();
    final fristController = TextEditingController(text: 'Morgen');
    String gewaehltesFach = _faecher.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Neue Hausaufgabe eintragen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: gewaehltesFach,
                    decoration: const InputDecoration(
                      labelText: 'Schulfach',
                      border: OutlineInputBorder(),
                    ),
                    items: _faecher.map((fach) {
                      return DropdownMenuItem(
                        value: fach,
                        child: Text(fach),
                      );
                    }).toList(),
                    onChanged: (neuerWert) {
                      setSheetState(() {
                        gewaehltesFach = neuerWert ?? 'Mathe';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titelController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Was ist zu tun?',
                      hintText: 'z. B. S. 18 Nr. 4 lösen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fristController,
                    decoration: const InputDecoration(
                      labelText: 'Bis wann?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final eingabe = titelController.text.trim();
                      if (eingabe.isEmpty) return;

                      setState(() {
                        _aufgaben.insert(
                          0,
                          Hausaufgabe(
                            fach: gewaehltesFach,
                            titel: eingabe,
                            frist: fristController.text.trim(),
                          ),
                        );
                      });
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text(
                      'Aufgabe speichern',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'Schulhelfer 1.0',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Noch $_offeneAnzahl offen',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _aufgaben.length,
        itemBuilder: (context, index) {
          final aufgabe = _aufgaben[index];
          final farbe = _fachFarbe(aufgabe.fach);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Checkbox(
                value: aufgabe.istErledigt,
                activeColor: farbe,
                onChanged: (neuerWert) {
                  setState(() {
                    aufgabe.istErledigt = neuerWert ?? false;
                  });
                },
              ),
              title: Text(
                aufgabe.titel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: aufgabe.istErledigt
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: aufgabe.istErledigt
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: farbe.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        aufgabe.fach,
                        style: TextStyle(
                          color: farbe,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fällig: ${aufgabe.frist}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {
                  setState(() {
                    _aufgaben.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: _oeffneEingabeBlatt,
        icon: const Icon(Icons.add),
        label: const Text('Neue Aufgabe'),
      ),
    );
  }
}
