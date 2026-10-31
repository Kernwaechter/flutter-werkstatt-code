import 'dart:async';
import 'package:flutter/material.dart';
import 'models/deck_status.dart';
import 'services/radio_synthesizer.dart';
import 'services/wav_recorder.dart';
import 'widgets/bandzaehlwerk.dart';
import 'widgets/kassetten_fenster.dart';
import 'widgets/mechanische_taste.dart';
import 'widgets/rec_level_poti.dart';
import 'widgets/vu_meter.dart';

void main() {
  runApp(const RadioRecorderApp());
}

class RadioRecorderApp extends StatelessWidget {
  const RadioRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'W-Deck 1986: Radio & WAV-Aufnahme',
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
  double _fortschritt = 0.10;
  double _rotationsWinkel = 0.0;
  int _zaehler = 50;

  double _recLevel = 0.85;
  double _pegelL = 0.0;
  double _pegelR = 0.0;
  int? _peakL;
  int? _peakR;

  final _synthesizer = RadioSynthesizer();
  final _recorder = WavRecorder();

  late final AnimationController _ticker;
  Timer? _audioTimer;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);

    // 50 Hz Audio-Stream (20 ms Bloecke à 882 Samples)
    _audioTimer =
        Timer.periodic(const Duration(milliseconds: 20), (t) async {
      // Immer synthetisieren fuer Monitor-VU-Meter
      final block = _synthesizer.erzeugeBlock(
        sampleCount: 882,
        recLevel: _recLevel,
      );

      // Wenn wir im REC-Modus sind, echte Samples in die WAV-Datei schreiben!
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
    _audioTimer?.cancel();
    if (_recorder.nimmtAuf) {
      _recorder.beendeAufnahme();
    }
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
        _zeigeHinweis('Bandende erreicht (Auto-Stop)');
      } else if (_fortschritt <= 0.0) {
        _fortschritt = 0.0;
        _stoppeDeck();
        _zeigeHinweis('Bandanfang erreicht (Auto-Stop)');
      }
    });
  }

  Future<void> _starteAufnahme() async {
    final pfad = await _recorder.starteAufnahme(
      dateiname: 'mixtape_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    setState(() {
      _status = DeckStatus.aufnahme;
    });
    if (!_ticker.isAnimating) _ticker.repeat();
    _zeigeHinweis('Aufnahme auf Kassette läuft!\nZiel: $pfad');
  }

  Future<void> _stoppeDeck() async {
    _ticker.stop();
    if (_status == DeckStatus.aufnahme && _recorder.nimmtAuf) {
      final pfad = await _recorder.beendeAufnahme();
      final groesseKb = (_recorder.aufgenommeneBytes / 1024).toStringAsFixed(1);
      _zeigeHinweis(
        'Aufnahme beendet!\nGespeichert: $pfad ($groesseKb KB)',
      );
    }
    setState(() {
      _status = DeckStatus.gestoppt;
    });
  }

  void _drueckeTaste(DeckStatus neuerStatus) {
    if (neuerStatus == DeckStatus.aufnahme) {
      if (_status != DeckStatus.aufnahme) {
        _starteAufnahme();
      }
    } else if (neuerStatus == DeckStatus.gestoppt) {
      _stoppeDeck();
    } else if (neuerStatus == DeckStatus.wiedergabe) {
      if (_recorder.nimmtAuf) {
        _recorder.beendeAufnahme();
      }
      setState(() {
        _status = DeckStatus.wiedergabe;
      });
      if (!_ticker.isAnimating) _ticker.repeat();
    } else if (neuerStatus == DeckStatus.pausiert) {
      if (_status != DeckStatus.gestoppt) {
        setState(() {
          _status = _status == DeckStatus.pausiert
              ? DeckStatus.wiedergabe
              : DeckStatus.pausiert;
        });
        if (_status == DeckStatus.pausiert) {
          _ticker.stop();
        } else {
          _ticker.repeat();
        }
      }
    } else {
      if (_recorder.nimmtAuf) {
        _recorder.beendeAufnahme();
      }
      setState(() {
        _status = neuerStatus;
      });
      if (!_ticker.isAnimating) _ticker.repeat();
    }
  }

  void _zeigeHinweis(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B20),
        title: const Text('W-Deck 1986: Radio & WAV-Aufnahme'),
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
                    Row(
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
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _status == DeckStatus.aufnahme
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                size: 10,
                                color: _status == DeckStatus.aufnahme
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _status == DeckStatus.aufnahme
                                    ? 'REC LIVE'
                                    : 'STANDBY',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: KassettenFenster(
                        bandFortschritt: _fortschritt,
                        rotationsWinkel: _rotationsWinkel,
                        mixtapeTitel: 'LIVE RADIO RECORDING 86',
                        bandTyp: 'METAL IV',
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
      ),
    );
  }
}
