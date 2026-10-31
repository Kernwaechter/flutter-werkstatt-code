import 'package:flutter/material.dart';
import 'models/messwert.dart';
import 'widgets/verlaufs_diagramm.dart';

void main() {
  runApp(const DiagrammInteraktionApp());
}

class DiagrammInteraktionApp extends StatelessWidget {
  const DiagrammInteraktionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kapitel 14: Diagramm & Interaktion',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const DiagrammScreen(),
    );
  }
}

class DiagrammScreen extends StatelessWidget {
  const DiagrammScreen({super.key});

  static const List<Messwert> _tagesverlauf = [
    Messwert(zeitpunkt: '06:00', watt: 0),
    Messwert(zeitpunkt: '08:00', watt: 450),
    Messwert(zeitpunkt: '10:00', watt: 1850),
    Messwert(zeitpunkt: '12:00', watt: 3900),
    Messwert(zeitpunkt: '13:00', watt: 4150),
    Messwert(zeitpunkt: '14:00', watt: 3800),
    Messwert(zeitpunkt: '16:00', watt: 2200),
    Messwert(zeitpunkt: '18:00', watt: 650),
    Messwert(zeitpunkt: '20:00', watt: 50),
    Messwert(zeitpunkt: '22:00', watt: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('24h-Verlauf & Maus-Hover'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SOLAR-ERTRAG ÜBER DEN TAG',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Peak: 4.150 W',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Fahre mit der Maus über das Diagramm, um Messwerte abzulesen:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: VerlaufsDiagramm(datenpunkte: _tagesverlauf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
