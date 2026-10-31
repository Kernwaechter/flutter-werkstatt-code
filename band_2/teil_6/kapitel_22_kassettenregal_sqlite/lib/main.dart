import 'dart:async';
import 'package:flutter/material.dart';
import 'models/deck_status.dart';
import 'services/radio_synthesizer.dart';
import 'services/wav_recorder.dart';
import 'widgets/bandzaehlwerk.dart';
import 'widgets/j_card_dialog.dart';
import 'widgets/kassetten_fenster.dart';
import 'widgets/mechanische_taste.dart';
import 'widgets/rec_level_poti.dart';
import 'widgets/vu_meter.dart';

void main() {
  runApp(const EjectDeckApp());
}

class EjectDeckApp extends StatelessWidget {
  const EjectDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'W-Deck: EJECT & Beschriftung',
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
    with TickerProviderStateMixin {
  DeckStatus _status = DeckStatus.gestoppt;
  double _fortschritt = 0.20;
  double _rotationsWinkel = 0.0;
  int _zaehler = 100;

  double _recLevel = 0.85;
  double _pegelL = 0.0;
  double _pegelR = 0.0;
  int? _peakL;
  int? _peakR;

  String _aktuellerTitel = 'FREITAGABEND RADIO-MIX 86';
  String _aktuellerTyp = 'CrO2 II';

  final _synthesizer = RadioSynthesizer();
  final _recorder = WavRecorder();

  late final AnimationController _ticker;
  late final AnimationController _klappenController;
  Timer? _audioTimer;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);

    _klappenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _audioTimer =
        Timer.periodic(const Duration(milliseconds: 20), (t) async {
      final block = _synthesizer.erzeugeBlock(
        sampleCount: 882,
        recLevel: _recLevel,
      );

      if (_status == DeckStatus.aufnahme && _recorder.nimmtAuf) {
        await _recorder.schreibeSamples(
          block.samplesLinks,
          block.samplesRechts,
        );
      }

      final activeSignal = (_status == DeckStatus.aufnahme ||
          _status == DeckStatus.wiedergabe);

      setState(() {
        if (activeSignal) {
          _pegelL = (_pegelL * 0.85) + (block.rmsLinks * 1.6 * 0.15);
          _pegelR = (_pegelR * 0.85) + (block.rmsRechts * 1.6 * 0.15);
          _peakL = (_pegelL * 16).round().clamp(0, 15);
          _peakR = (_pegelR * 16).round().clamp(0, 15);
        } else {
          _pegelL *= 0.8;
          _pegelR *= 0.8;
          if (_pegelL < 0.02) _pegelL = 0.0;
          if (_pegelR < 0.02) _pegelR = 0.0;
          _peakL = null;
          _peakR = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _klappenController.dispose();
    _audioTimer?.cancel();
    if (_recorder.nimmtAuf) _recorder.beendeAufnahme();
    super.dispose();
  }

  void _onTick() {
    if (_status == DeckStatus.gestoppt || _status == DeckStatus.pausiert) {
      return;
    }

    setState(() {
      double tempo = 0.0004;
      if (_status == DeckStatus.vorlauf) tempo = 0.0025;
      if (_status == DeckStatus.ruecklauf) tempo = -0.0025;

      _fortschritt += tempo;
      _rotationsWinkel += tempo * 80;
      _zaehler = (_fortschritt * 500).round().clamp(0, 999);

      if (_fortschritt >= 1.0) {
        _fortschritt = 1.0;
        _stoppeDeck();
      } else if (_fortschritt <= 0.0) {
        _fortschritt = 0.0;
        _stoppeDeck();
      }
    });
  }

  Future<void> _stoppeDeck() async {
    _ticker.stop();
    if (_status == DeckStatus.aufnahme && _recorder.nimmtAuf) {
      await _recorder.beendeAufnahme();
    }
    setState(() {
      _status = DeckStatus.gestoppt;
    });
  }

  Future<void> _drueckeStopOderEject() async {
    // 1. Wenn das Deck laeuft, erst anhalten
    if (_status != DeckStatus.gestoppt) {
      await _stoppeDeck();
      return;
    }

    // 2. Wenn das Deck bereits steht: EJECT Klappe aufschwingen!
    await _klappenController.forward();

    if (!mounted) return;

    // 3. Beschriftungsdialog oeffnen
    final ergebnis = await showDialog<KassetteInfo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => JCardDialog(vorgeschlagenerTitel: _aktuellerTitel),
    );

    // 4. Klappe wieder schliessen
    await _klappenController.reverse();

    if (ergebnis != null) {
      setState(() {
        _aktuellerTitel = ergebnis.titel;
        _aktuellerTyp = ergebnis.bandTyp;
        _zaehler = 0;
        _fortschritt = 0.0;
      });
      _zeigeHinweis(
        'Kassette beschriftet: „${ergebnis.titel}“\n'
        'Bereit im Deck!',
      );
    }
  }

  Future<void> _starteAufnahme() async {
    await _recorder.starteAufnahme();
    setState(() => _status = DeckStatus.aufnahme);
    if (!_ticker.isAnimating) _ticker.repeat();
  }

  void _drueckeTaste(DeckStatus neuerStatus) {
    if (neuerStatus == DeckStatus.gestoppt) {
      _drueckeStopOderEject();
    } else if (neuerStatus == DeckStatus.aufnahme) {
      if (_status != DeckStatus.aufnahme) _starteAufnahme();
    } else {
      if (_recorder.nimmtAuf) _recorder.beendeAufnahme();
      setState(() => _status = neuerStatus);
      if (!_ticker.isAnimating) _ticker.repeat();
    }
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
        title: const Text('W-Deck 1986: STOP / EJECT & J-Card'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 840),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A404D), width: 3),
            ),
            child: Column(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kassettenfenster mit 3D-Klapp-Animation!
                    Expanded(
                      flex: 5,
                      child: AnimatedBuilder(
                        animation: _klappenController,
                        builder: (context, child) {
                          // 3D-Schwenkung nach vorne um 25 Grad (0.43 rad)
                          final winkel =
                              _klappenController.value * 0.43;
                          return Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015) // Perspektive
                              ..rotateX(winkel),
                            child: child,
                          );
                        },
                        child: KassettenFenster(
                          bandFortschritt: _fortschritt,
                          rotationsWinkel: _rotationsWinkel,
                          mixtapeTitel: _aktuellerTitel,
                          bandTyp: _aktuellerTyp,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          StereoVuMeter(
                            pegelLinks: _pegelL,
                            pegelRechts: _pegelR,
                            peakLinks: _peakL,
                            peakRechts: _peakR,
                          ),
                          const SizedBox(height: 16),
                          RecLevelPoti(
                            wert: _recLevel,
                            onChanged: (val) =>
                                setState(() => _recLevel = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
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
                      onGedrueckt: () =>
                          _drueckeTaste(DeckStatus.vorlauf),
                    ),
                    MechanischeTaste(
                      beschriftung: 'STOP/EJECT',
                      icon: Icons.eject,
                      istGedrueckt: _status == DeckStatus.gestoppt,
                      onGedrueckt: _drueckeStopOderEject,
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
      ),
    );
  }
}
