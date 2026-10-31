import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models/deck_status.dart';
import 'widgets/bandzaehlwerk.dart';
import 'widgets/kassetten_fenster.dart';
import 'widgets/mechanische_taste.dart';
import 'widgets/rec_level_poti.dart';
import 'widgets/vu_meter.dart';

void main() {
  runApp(const VuMeterApp());
}

class VuMeterApp extends StatelessWidget {
  const VuMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stereo VU-Meter',
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
  DeckStatus _status = DeckStatus.wiedergabe;
  double _fortschritt = 0.35;
  double _rotationsWinkel = 0.0;
  int _zaehler = 175;

  double _recLevel = 0.75;
  double _pegelL = 0.0;
  double _pegelR = 0.0;
  int? _peakL;
  int? _peakR;
  int _peakHoldL = 0;
  int _peakHoldR = 0;

  late final AnimationController _ticker;
  Timer? _audioSimTimer;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
    _ticker.repeat();

    // 50 Hz Audio-Signal-Simulation mit Ballistik & Decay
    _audioSimTimer =
        Timer.periodic(const Duration(milliseconds: 25), (t) {
      if (_status != DeckStatus.wiedergabe &&
          _status != DeckStatus.aufnahme) {
        setState(() {
          _pegelL *= 0.85;
          _pegelR *= 0.85;
          if (_pegelL < 0.02) _pegelL = 0.0;
          if (_pegelR < 0.02) _pegelR = 0.0;
          _peakL = null;
          _peakR = null;
        });
        return;
      }

      final rnd = math.Random();
      final baseMusic = 0.5 + 0.3 * math.sin(t.tick * 0.15);
      final rawL = (baseMusic + rnd.nextDouble() * 0.3) * _recLevel;
      final rawR = (baseMusic + rnd.nextDouble() * 0.3) * _recLevel;

      setState(() {
        // Attack (schnell) & Decay (sanftes Abklingen)
        if (rawL > _pegelL) {
          _pegelL = rawL;
        } else {
          _pegelL = _pegelL * 0.90 + rawL * 0.10;
        }

        if (rawR > _pegelR) {
          _pegelR = rawR;
        } else {
          _pegelR = _pegelR * 0.90 + rawR * 0.10;
        }

        final aktIndexL = (_pegelL * 16).round().clamp(0, 15);
        final aktIndexR = (_pegelR * 16).round().clamp(0, 15);

        // Peak Hold Links
        if (_peakL == null || aktIndexL >= _peakL!) {
          _peakL = aktIndexL;
          _peakHoldL = 40; // ca. 1 Sekunde halten
        } else if (_peakHoldL > 0) {
          _peakHoldL--;
        } else {
          _peakL = aktIndexL;
        }

        // Peak Hold Rechts
        if (_peakR == null || aktIndexR >= _peakR!) {
          _peakR = aktIndexR;
          _peakHoldR = 40;
        } else if (_peakHoldR > 0) {
          _peakHoldR--;
        } else {
          _peakR = aktIndexR;
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audioSimTimer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (_status == DeckStatus.gestoppt || _status == DeckStatus.pausiert) {
      return;
    }

    setState(() {
      double tempo = 0.0005;
      if (_status == DeckStatus.vorlauf) tempo = 0.0025;
      if (_status == DeckStatus.ruecklauf) tempo = -0.0025;

      _fortschritt += tempo;
      _rotationsWinkel += tempo * 80;
      _zaehler = (_fortschritt * 500).round().clamp(0, 999);

      if (_fortschritt >= 1.0) {
        _fortschritt = 1.0;
        _status = DeckStatus.gestoppt;
        _ticker.stop();
      } else if (_fortschritt <= 0.0) {
        _fortschritt = 0.0;
        _status = DeckStatus.gestoppt;
        _ticker.stop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B20),
        title: const Text('W-Deck 1986: Stereo VU-Meter & Pegel'),
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
                // Obere Reihe: Kassettenfenster links, VU-Meter & Poti rechts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: KassettenFenster(
                        bandFortschritt: _fortschritt,
                        rotationsWinkel: _rotationsWinkel,
                        mixtapeTitel: 'RETRO SYNTHWAVE 1986',
                        bandTyp: 'CrO2 II',
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
