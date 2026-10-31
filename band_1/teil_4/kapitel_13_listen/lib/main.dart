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
    Hausaufgabe(
      fach: 'Physik',
      titel: 'Versuchsprotokoll Stromkreis',
      frist: 'Freitag',
      istErledigt: true,
    ),
    Hausaufgabe(
      fach: 'Informatik',
      titel: 'Eigene Datenklasse in Dart bauen',
      frist: 'Heute',
    ),
  ];

  int get _offeneAnzahl =>
      _aufgaben.where((a) => !a.istErledigt).length;

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
                activeColor: const Color(0xFF2563EB),
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
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${aufgabe.fach} · Fällig: ${aufgabe.frist}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
