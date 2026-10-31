import 'dart:async';
import 'package:flutter/material.dart';
import 'models/deck_status.dart';
import 'widgets/bandzaehlwerk.dart';
import 'widgets/mechanische_taste.dart';

void main() {
  runApp(const KassettendeckApp());
}

class KassettendeckApp extends StatelessWidget {
  const KassettendeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'W-Deck 1986',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0C0E),
      ),
      home: const DeckScreen(),
    );
  }
}

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  DeckStatus _status = DeckStatus.gestoppt;
  int _zaehler = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (_status == DeckStatus.wiedergabe ||
          _status == DeckStatus.aufnahme) {
        setState(() => _zaehler = (_zaehler + 1).clamp(0, 999));
      } else if (_status == DeckStatus.vorlauf) {
        setState(() => _zaehler = (_zaehler + 4).clamp(0, 999));
      } else if (_status == DeckStatus.ruecklauf) {
        setState(() => _zaehler = (_zaehler - 4).clamp(0, 999));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _drueckeTaste(DeckStatus neuerStatus) {
    setState(() {
      if (neuerStatus == DeckStatus.gestoppt) {
        _status = DeckStatus.gestoppt;
      } else if (neuerStatus == DeckStatus.pausiert) {
        if (_status != DeckStatus.gestoppt) {
          _status = _status == DeckStatus.pausiert
              ? DeckStatus.wiedergabe
              : DeckStatus.pausiert;
        }
      } else {
        _status = neuerStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B20),
        title: const Text('W-Deck 1986: Frontplatte & Mechanik'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 820),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A404D), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Marken-Kopfzeile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'W-DECK 1986',
                        style: TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'STEREO CASSETTE DECK',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Bandzaehlwerk(
                    zaehlerstand: _zaehler,
                    onReset: () => setState(() => _zaehler = 0),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Dummy-Bereich fuer Kassettenfach (kommt in Kap 18)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1115),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.album,
                          size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 8),
                      Text(
                        'STATUS: ${_status.name.toUpperCase()}',
                        style: TextStyle(
                          color: _status == DeckStatus.aufnahme
                              ? const Color(0xFFEF4444)
                              : _status == DeckStatus.wiedergabe
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Tastenleiste
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  MechanischeTaste(
                    beschriftung: 'REC',
                    icon: Icons.fiber_manual_record,
                    akzentFarbe: const Color(0xFFEF4444),
                    istGedrueckt: _status == DeckStatus.aufnahme,
                    onGedrueckt: () =>
                        _drueckeTaste(DeckStatus.aufnahme),
                  ),
                  MechanischeTaste(
                    beschriftung: 'PLAY',
                    icon: Icons.play_arrow,
                    akzentFarbe: const Color(0xFF10B981),
                    istGedrueckt: _status == DeckStatus.wiedergabe,
                    onGedrueckt: () =>
                        _drueckeTaste(DeckStatus.wiedergabe),
                  ),
                  MechanischeTaste(
                    beschriftung: 'REW',
                    icon: Icons.fast_rewind,
                    istGedrueckt: _status == DeckStatus.ruecklauf,
                    onGedrueckt: () =>
                        _drueckeTaste(DeckStatus.ruecklauf),
                  ),
                  MechanischeTaste(
                    beschriftung: 'FF',
                    icon: Icons.fast_forward,
                    istGedrueckt: _status == DeckStatus.vorlauf,
                    onGedrueckt: () => _drueckeTaste(DeckStatus.vorlauf),
                  ),
                  MechanischeTaste(
                    beschriftung: 'STOP',
                    icon: Icons.stop,
                    istGedrueckt: _status == DeckStatus.gestoppt,
                    onGedrueckt: () =>
                        _drueckeTaste(DeckStatus.gestoppt),
                  ),
                  MechanischeTaste(
                    beschriftung: 'PAUSE',
                    icon: Icons.pause,
                    akzentFarbe: const Color(0xFFF59E0B),
                    istGedrueckt: _status == DeckStatus.pausiert,
                    onGedrueckt: () =>
                        _drueckeTaste(DeckStatus.pausiert),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
