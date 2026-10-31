import 'package:flutter/material.dart';
import 'widgets/libellen_painter.dart';

void main() {
  runApp(const WasserwaageApp());
}

class WasserwaageApp extends StatelessWidget {
  const WasserwaageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wasserwaage mit Libelle',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const WasserwaageScreen(),
    );
  }
}

class WasserwaageScreen extends StatefulWidget {
  const WasserwaageScreen({super.key});

  @override
  State<WasserwaageScreen> createState() =>
      _WasserwaageScreenState();
}

class _WasserwaageScreenState extends State<WasserwaageScreen>
    with SingleTickerProviderStateMixin {
  double _zielX = 0.0;
  double _zielY = 0.0;

  double _aktuelleX = 0.0;
  double _aktuelleY = 0.0;

  @override
  void initState() {
    super.initState();
    // Sanfte Interpolation für flüssige Libellen-Physik
    createTicker((_) {
      if ((_aktuelleX - _zielX).abs() > 0.01 ||
          (_aktuelleY - _zielY).abs() > 0.01) {
        setState(() {
          _aktuelleX += (_zielX - _aktuelleX) * 0.15;
          _aktuelleY += (_zielY - _aktuelleY) * 0.15;
        });
      }
    }).start();
  }

  @override
  Widget build(BuildContext context) {
    final bool istExakt =
        _aktuelleX.abs() <= 0.5 && _aktuelleY.abs() <= 0.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wasserwaage & Libelle'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Die runde Libelle mit CustomPainter
              SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: LibellenPainter(
                    neigungX: _aktuelleX,
                    neigungY: _aktuelleY,
                    istExakt: istExakt,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: istExakt
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFE11D48).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: istExakt
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE11D48),
                  ),
                ),
                child: Text(
                  istExakt
                      ? '✓ PERFEKT WAAGERECHT'
                      : '⚡ NICHT IM WASSER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: istExakt
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE11D48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pitch: ${_aktuelleX.toStringAsFixed(1)}° · '
                'Roll: ${_aktuelleY.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 17,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              // Simulation per Slider
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
                      'Neigung simulieren (Pitch & Roll)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Slider(
                      value: _zielX,
                      min: -30.0,
                      max: 30.0,
                      label: '${_zielX.toStringAsFixed(1)}°',
                      onChanged: (val) {
                        setState(() => _zielX = val);
                      },
                    ),
                    Slider(
                      value: _zielY,
                      min: -30.0,
                      max: 30.0,
                      activeColor: const Color(0xFF38BDF8),
                      label: '${_zielY.toStringAsFixed(1)}°',
                      onChanged: (val) {
                        setState(() => _zielY = val);
                      },
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _zielX = 0.0;
                          _zielY = 0.0;
                        });
                      },
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Ins Zentrum setzen'),
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
