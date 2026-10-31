import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const AkustikPegelApp());
}

class AkustikPegelApp extends StatelessWidget {
  const AkustikPegelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akustik-Pegelmesser',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const PegelmesserScreen(),
    );
  }
}

class PegelmesserScreen extends StatefulWidget {
  const PegelmesserScreen({super.key});

  @override
  State<PegelmesserScreen> createState() => _PegelmesserScreenState();
}

class _PegelmesserScreenState extends State<PegelmesserScreen> {
  Timer? _messTimer;
  double _aktuellerPegeldB = 32.0;
  double _peakPegeldB = 32.0;
  bool _aufnahmeAktiv = true;

  final List<double> _verlauf = List.generate(24, (_) => 30.0);

  @override
  void initState() {
    super.initState();
    _starteMessung();
  }

  void _starteMessung() {
    _messTimer?.cancel();
    _messTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _messeSample(),
    );
  }

  void _messeSample() {
    if (!_aufnahmeAktiv) return;

    final random = math.Random();
    // Simuliert realistisches Umgebungsrauschen zwischen 30 dB und 85 dB
    final double basis = 35.0 + random.nextDouble() * 20.0;
    final double spitze = random.nextDouble() > 0.85
        ? random.nextDouble() * 30.0
        : 0.0;
    final double messwert = (basis + spitze).clamp(25.0, 95.0);

    setState(() {
      _aktuellerPegeldB = messwert;
      if (messwert > _peakPegeldB) {
        _peakPegeldB = messwert;
      } else {
        _peakPegeldB = (_peakPegeldB - 0.5).clamp(30.0, 100.0);
      }
      _verlauf.removeAt(0);
      _verlauf.add(messwert);
    });
  }

  @override
  void dispose() {
    _messTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool istLaut = _aktuellerPegeldB > 75.0;
    final akzentFarbe = istLaut
        ? const Color(0xFFE11D48)
        : (_aktuellerPegeldB > 60.0
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akustik-Pegelmesser (dB)'),
        actions: [
          IconButton(
            icon: Icon(
              _aufnahmeAktiv ? Icons.pause_circle : Icons.play_circle,
            ),
            tooltip: _aufnahmeAktiv ? 'Pausieren' : 'Fortsetzen',
            onPressed: () {
              setState(() => _aufnahmeAktiv = !_aufnahmeAktiv);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_aktuellerPegeldB.toStringAsFixed(1)} dB(A)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: akzentFarbe,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spitzenwert (Peak): ${_peakPegeldB.toStringAsFixed(1)} dB(A)',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 36),
              // Balken-Equalizer
              Container(
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _verlauf.map((wert) {
                    final double hoehe = ((wert - 25.0) / 70.0).clamp(0.05, 1.0);
                    final balkenFarbe = wert > 75.0
                        ? const Color(0xFFE11D48)
                        : (wert > 60.0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF38BDF8));

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 108 * hoehe,
                        decoration: BoxDecoration(
                          color: balkenFarbe,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              _baueStatusBadge(istLaut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baueStatusBadge(bool istLaut) {
    final statusFarbe = istLaut
        ? const Color(0xFFE11D48)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: statusFarbe.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: statusFarbe),
      ),
      child: Text(
        istLaut
            ? '⚡ LAUTSTÄRKE-WARNUNG (> 75 dB)'
            : '✓ ANGENEHME LAUTSTÄRKE',
        style: TextStyle(
          color: statusFarbe,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
