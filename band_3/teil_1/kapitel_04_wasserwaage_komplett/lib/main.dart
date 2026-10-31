import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/libellen_painter.dart';

void main() {
  runApp(const WerkbankWaageApp());
}

class WerkbankWaageApp extends StatelessWidget {
  const WerkbankWaageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Werkbank-Wasserwaage & Pegel',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const WerkbankScreen(),
    );
  }
}

class WerkbankScreen extends StatefulWidget {
  const WerkbankScreen({super.key});

  @override
  State<WerkbankScreen> createState() => _WerkbankScreenState();
}

class _WerkbankScreenState extends State<WerkbankScreen>
    with SingleTickerProviderStateMixin {
  double _zielX = 0.0;
  double _zielY = 0.0;

  double _aktuelleX = 0.0;
  double _aktuelleY = 0.0;

  double _offsetX = 0.0;
  double _offsetY = 0.0;

  double _pegelDb = 35.0;
  Timer? _pegelTimer;
  bool _warBereitsAusgerichtet = false;

  @override
  void initState() {
    super.initState();
    createTicker((_) {
      if ((_aktuelleX - _zielX).abs() > 0.01 ||
          (_aktuelleY - _zielY).abs() > 0.01) {
        setState(() {
          _aktuelleX += (_zielX - _aktuelleX) * 0.16;
          _aktuelleY += (_zielY - _aktuelleY) * 0.16;
        });

        final bool istExakt =
            (_aktuelleX - _offsetX).abs() <= 0.5 &&
            (_aktuelleY - _offsetY).abs() <= 0.5;

        if (istExakt && !_warBereitsAusgerichtet) {
          HapticFeedback.selectionClick();
          _warBereitsAusgerichtet = true;
        } else if (!istExakt) {
          _warBereitsAusgerichtet = false;
        }
      }
    }).start();

    _pegelTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) {
        final rnd = math.Random();
        setState(() {
          _pegelDb = (32.0 + rnd.nextDouble() * 25.0).clamp(20.0, 95.0);
        });
      },
    );
  }

  @override
  void dispose() {
    _pegelTimer?.cancel();
    super.dispose();
  }

  void _kalibrieren() {
    setState(() {
      _offsetX = _aktuelleX;
      _offsetY = _aktuelleY;
    });
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nullpunkt erfolgreich kalibriert!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double nettox = _aktuelleX - _offsetX;
    final double nettoY = _aktuelleY - _offsetY;
    final bool istExakt = nettox.abs() <= 0.5 && nettoY.abs() <= 0.5;

    final akzentFarbe = istExakt
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor-Wasserwaage & Akustik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Als Nullpunkt kalibrieren',
            onPressed: _kalibrieren,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 270,
                height: 270,
                child: CustomPaint(
                  painter: LibellenPainter(
                    neigungX: nettox,
                    neigungY: nettoY,
                    istExakt: istExakt,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: akzentFarbe.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: akzentFarbe),
                ),
                child: Text(
                  istExakt ? '✓ PERFEKT WAAGERECHT' : '⚡ GENEIGT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: akzentFarbe,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _baueKompaktKachel(
                    'X (Pitch)',
                    '${nettox.toStringAsFixed(1)}°',
                  ),
                  const SizedBox(width: 12),
                  _baueKompaktKachel(
                    'Y (Roll)',
                    '${nettoY.toStringAsFixed(1)}°',
                  ),
                  const SizedBox(width: 12),
                  _baueKompaktKachel(
                    'Akustik',
                    '${_pegelDb.toStringAsFixed(0)} dB',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Desktop-Simulation (Winkel testen)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Slider(
                      value: _zielX,
                      min: -25.0,
                      max: 25.0,
                      label: '${_zielX.toStringAsFixed(1)}°',
                      onChanged: (v) => setState(() => _zielX = v),
                    ),
                    Slider(
                      value: _zielY,
                      min: -25.0,
                      max: 25.0,
                      activeColor: const Color(0xFF38BDF8),
                      label: '${_zielY.toStringAsFixed(1)}°',
                      onChanged: (v) => setState(() => _zielY = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _zielX = 0.0;
                              _zielY = 0.0;
                            });
                          },
                          child: const Text('Auf 0° zentrieren'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _offsetX = 0.0;
                              _offsetY = 0.0;
                            });
                          },
                          child: const Text('Reset'),
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

  Widget _baueKompaktKachel(String titel, String wert) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Text(
            titel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            wert,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
