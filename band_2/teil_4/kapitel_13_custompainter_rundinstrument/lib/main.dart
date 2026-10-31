import 'package:flutter/material.dart';
import 'widgets/energie_tacho.dart';

void main() {
  runApp(const EnergieCockpitApp());
}

class EnergieCockpitApp extends StatelessWidget {
  const EnergieCockpitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kapitel 13: Rundinstrument',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const CockpitScreen(),
    );
  }
}

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key});

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  double _aktuelleLeistung = 2850.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Energie-Cockpit: Rundinstrument'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SOLAR-LEISTUNG (LIVE)',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    EnergieTacho(
                      wertInWatt: _aktuelleLeistung,
                      maximalWert: 5000.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messwert simulieren (Schieberegler):',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    Slider(
                      value: _aktuelleLeistung,
                      min: 0.0,
                      max: 5000.0,
                      divisions: 50,
                      activeColor: const Color(0xFF38BDF8),
                      label: '${_aktuelleLeistung.toInt()} W',
                      onChanged: (val) {
                        setState(() => _aktuelleLeistung = val);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _aktuelleLeistung = 850),
                          child: const Text('850 W'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _aktuelleLeistung = 2850),
                          child: const Text('2.850 W'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _aktuelleLeistung = 4600),
                          child: const Text('4.600 W'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
