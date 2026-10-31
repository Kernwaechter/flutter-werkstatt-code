import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

// Repräsentiert die Render-Metriken eines einzelnen UI-Frames
class FrameMessung {
  final Duration buildDauer;
  final Duration rasterDauer;
  final Duration gesamtDauer;
  final bool istJank; // Überschreitet 16.6ms (60 FPS Budget)

  const FrameMessung({
    required this.buildDauer,
    required this.rasterDauer,
    required this.gesamtDauer,
    required this.istJank,
  });
}

class PerformanceWaecher {
  static const double budget60FpsMs = 16.66;
  final List<FrameMessung> _historie = [];
  TimingsCallback? _callback;

  List<FrameMessung> get letzteFrames =>
      List.unmodifiable(_historie);

  void starten(void Function() onUpdate) {
    _callback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        final buildDur = timing.buildDuration;
        final rasterDur = timing.rasterDuration;
        final gesamtDur = timing.totalSpan;
        final bool jank =
            gesamtDur.inMicroseconds > (budget60FpsMs * 1000);

        _historie.add(
          FrameMessung(
            buildDauer: buildDur,
            rasterDauer: rasterDur,
            gesamtDauer: gesamtDur,
            istJank: jank,
          ),
        );

        if (_historie.length > 50) {
          _historie.removeAt(0);
        }
      }
      onUpdate();
    };

    WidgetsBinding.instance.addTimingsCallback(_callback!);
  }

  void stoppen() {
    if (_callback != null) {
      WidgetsBinding.instance.removeTimingsCallback(_callback!);
      _callback = null;
    }
  }
}

void main() {
  runApp(const ProfilingApp());
}

class ProfilingApp extends StatelessWidget {
  const ProfilingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Performance & Profiling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ProfilingScreen(),
    );
  }
}

class ProfilingScreen extends StatefulWidget {
  const ProfilingScreen({super.key});

  @override
  State<ProfilingScreen> createState() => _ProfilingScreenState();
}

class _ProfilingScreenState extends State<ProfilingScreen> {
  final PerformanceWaecher _waechter = PerformanceWaecher();
  bool _simuliereLast = false;
  Timer? _lastTimer;

  // Absichtlicher Speicherpuffer zur Demonstration von Heap-Wachstum
  final List<List<int>> _leakSpeicher = [];

  @override
  void initState() {
    super.initState();
    _waechter.starten(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lastTimer?.cancel();
    _waechter.stoppen();
    super.dispose();
  }

  void _toggleLast(bool aktiv) {
    setState(() {
      _simuliereLast = aktiv;
      if (aktiv) {
        _lastTimer = Timer.periodic(
          const Duration(milliseconds: 32),
          (_) {
            // CPU-Last erzeugen, um Framedrops zu provozieren
            int summe = 0;
            for (int i = 0; i < 2000000; i++) {
              summe += (i % 7);
            }
            if (summe < 0) debugPrint('$summe');
          },
        );
      } else {
        _lastTimer?.cancel();
      }
    });
  }

  void _allokiereSpeicher() {
    setState(() {
      // 5 MB Dummy-Speicher erzeugen
      _leakSpeicher.add(List<int>.filled(5 * 1024 * 1024, 42));
    });
  }

  void _leereSpeicher() {
    setState(() {
      _leakSpeicher.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final frames = _waechter.letzteFrames;
    final int jankCount = frames.where((f) => f.istJank).length;
    final double jankRate =
        frames.isNotEmpty ? (jankCount / frames.length) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('Performance Profiling & Budget'),
        backgroundColor: const Color(0xFF1E272C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsHeader(jankCount, jankRate),
            const SizedBox(height: 20),
            _buildFrameTimeline(frames),
            const SizedBox(height: 24),
            _buildControlCard(),
            const SizedBox(height: 16),
            _buildMemoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int jankCount, double jankRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: jankCount == 0
              ? const Color(0xFF4CAF50)
              : const Color(0xFFEF5350),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '60-FPS Budget (16.6 ms)',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Jank: ${jankRate.toStringAsFixed(1)}% '
                '($jankCount Frames)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: jankCount == 0
                      ? const Color(0xFF00E676)
                      : const Color(0xFFEF5350),
                ),
              ),
            ],
          ),
          Icon(
            jankCount == 0 ? Icons.speed : Icons.warning_amber,
            color: jankCount == 0
                ? const Color(0xFF00E676)
                : const Color(0xFFEF5350),
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildFrameTimeline(List<FrameMessung> frames) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Frame-Rendering (Letzte 50 Frames)',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Limit: 16.6ms',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final f in frames)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 1.5,
                      ),
                      height: (f.gesamtDauer.inMicroseconds / 333.0)
                          .clamp(4.0, 80.0),
                      decoration: BoxDecoration(
                        color: f.istJank
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF10B981),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI-Thread CPU-Last simulieren',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Provoziert Jank durch schwere Schleifen',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          Switch(
            value: _simuliereLast,
            onChanged: _toggleLast,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard() {
    final int mbBelegt = _leakSpeicher.length * 5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulierter Heap-Speicher: $mbBelegt MB',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF80CBC4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _allokiereSpeicher,
                  icon: const Icon(Icons.add),
                  label: const Text('+5 MB Heap'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: mbBelegt > 0 ? _leereSpeicher : null,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('GC Freigeben'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
