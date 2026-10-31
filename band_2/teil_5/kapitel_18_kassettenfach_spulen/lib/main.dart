import 'package:flutter/material.dart';
import 'models/deck_status.dart';
import 'widgets/bandzaehlwerk.dart';
import 'widgets/kassetten_fenster.dart';
import 'widgets/mechanische_taste.dart';

void main() {
  runApp(const KassettenfachApp());
}

class KassettenfachApp extends StatelessWidget {
  const KassettenfachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kassettenfach & Spulen',
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

class _DeckScreenState extends State<DeckScreen>
    with SingleTickerProviderStateMixin {
  DeckStatus _status = DeckStatus.gestoppt;
  double _fortschritt = 0.25; // 25% abgespielt
  double _rotationsWinkel = 0.0;
  int _zaehler = 124;

  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_status == DeckStatus.gestoppt || _status == DeckStatus.pausiert) {
      return;
    }

    setState(() {
      double tempo = 0.0005; // Normales Abspieltempo
      if (_status == DeckStatus.vorlauf) tempo = 0.0025;
      if (_status == DeckStatus.ruecklauf) tempo = -0.0025;

      _fortschritt += tempo;
      _rotationsWinkel += tempo * 80;

      // Bandzaehlwerk mitrechnen
      _zaehler = (_fortschritt * 500).round().clamp(0, 999);

      // Auto-Stop am Bandende!
      if (_fortschritt >= 1.0) {
        _fortschritt = 1.0;
        _status = DeckStatus.gestoppt;
        _ticker.stop();
        _zeigeHinweis('Bandende erreicht (Auto-Stop)');
      } else if (_fortschritt <= 0.0) {
        _fortschritt = 0.0;
        _status = DeckStatus.gestoppt;
        _ticker.stop();
        _zeigeHinweis('Bandanfang erreicht (Auto-Stop)');
      }
    });
  }

  void _drueckeTaste(DeckStatus neuerStatus) {
    setState(() {
      if (neuerStatus == DeckStatus.gestoppt) {
        _status = DeckStatus.gestoppt;
        _ticker.stop();
      } else if (neuerStatus == DeckStatus.pausiert) {
        if (_status != DeckStatus.gestoppt) {
          if (_status == DeckStatus.pausiert) {
            _status = DeckStatus.wiedergabe;
            _ticker.repeat();
          } else {
            _status = DeckStatus.pausiert;
            _ticker.stop();
          }
        }
      } else {
        _status = neuerStatus;
        if (!_ticker.isAnimating) {
          _ticker.repeat();
        }
      }
    });
  }

  void _zeigeHinweis(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B20),
        title: const Text('W-Deck 1986: Kassettenfach & Spulen'),
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'W-DECK 1986',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Bandzaehlwerk(
                    zaehlerstand: _zaehler,
                    onReset: () => setState(() => _zaehler = 0),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Das echte beleuchtete Kassettenfenster!
              KassettenFenster(
                bandFortschritt: _fortschritt,
                rotationsWinkel: _rotationsWinkel,
                mixtapeTitel: 'RETRO SYNTHWAVE 1986',
                bandTyp: 'CrO2 II',
              ),
              const SizedBox(height: 12),
              Text(
                'Band-Position: ${(_fortschritt * 100).toInt()}%  ·  '
                'Status: ${_status.name.toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
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
