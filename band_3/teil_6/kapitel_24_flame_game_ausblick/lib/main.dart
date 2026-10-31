import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Repräsentiert ein physikalisches 2D-Objekt im Game-Loop
class RaumschiffComponent {
  double x = 150.0;
  double y = 250.0;
  double vx = 0.0;
  double vy = 0.0;
  double winkel = 0.0;
  final double radius = 16.0;

  void update(
    double dt,
    double tiltX,
    double tiltY,
    Size boundaries,
  ) {
    // Steuerung über Neigungssensor (oder Touch-Simulation)
    vx += tiltX * 450.0 * dt;
    vy += tiltY * 450.0 * dt;

    // Reibung (Dämpfung)
    vx *= 0.96;
    vy *= 0.96;

    x += vx * dt;
    y += vy * dt;

    // Kollision mit Bildschirmrändern
    if (x < radius) {
      x = radius;
      vx = -vx * 0.7;
    } else if (x > boundaries.width - radius) {
      x = boundaries.width - radius;
      vx = -vx * 0.7;
    }

    if (y < radius) {
      y = radius;
      vy = -vy * 0.7;
    } else if (y > boundaries.height - radius) {
      y = boundaries.height - radius;
      vy = -vy * 0.7;
    }

    if (vx.abs() > 1 || vy.abs() > 1) {
      winkel = math.atan2(vy, vx) + (math.pi / 2);
    }
  }

  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(winkel);

    final path = Path()
      ..moveTo(0, -radius * 1.3)
      ..lineTo(-radius * 0.9, radius)
      ..lineTo(0, radius * 0.5)
      ..lineTo(radius * 0.9, radius)
      ..close();

    canvas.drawPath(path, paint);

    final glow = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius * 1.2, glow);

    canvas.restore();
  }
}

class Partikel {
  double x;
  double y;
  double vx;
  double vy;
  double lebenszeit;
  final double maxLebenszeit;
  final Color farbe;

  Partikel({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.lebenszeit,
    required this.maxLebenszeit,
    required this.farbe,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    lebenszeit -= dt;
    return lebenszeit > 0;
  }

  void render(Canvas canvas) {
    final double alpha = (lebenszeit / maxLebenszeit).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = farbe.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 3.0 * alpha, paint);
  }
}

void main() {
  runApp(const FlameAusblickApp());
}

class FlameAusblickApp extends StatelessWidget {
  const FlameAusblickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ausblick auf Band 4: Flame Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameLoopScreen(),
    );
  }
}

class GameLoopScreen extends StatefulWidget {
  const GameLoopScreen({super.key});

  @override
  State<GameLoopScreen> createState() => _GameLoopScreenState();
}

class _GameLoopScreenState extends State<GameLoopScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  final RaumschiffComponent _schiff = RaumschiffComponent();
  final List<Partikel> _partikel = [];
  final math.Random _rnd = math.Random();

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  int _fps = 60;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt =
        (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt > 0 && dt < 0.2) {
      _gameUpdate(dt);
    }

    _frameCount++;
    final now = DateTime.now();
    if (now.difference(_lastFpsUpdate).inMilliseconds >= 500) {
      setState(() {
        _fps = (_frameCount * 2);
        _frameCount = 0;
        _lastFpsUpdate = now;
      });
    }
  }

  void _gameUpdate(double dt) {
    final size = MediaQuery.of(context).size;
    final gameSize = Size(size.width, size.height - 140);

    _schiff.update(dt, _tiltX, _tiltY, gameSize);

    // Antriebs-Partikel erzeugen
    if (_tiltX.abs() > 0.05 || _tiltY.abs() > 0.05) {
      for (int i = 0; i < 2; i++) {
        _partikel.add(
          Partikel(
            x: _schiff.x,
            y: _schiff.y,
            vx: -_schiff.vx * 0.4 + (_rnd.nextDouble() - 0.5) * 40,
            vy: -_schiff.vy * 0.4 + (_rnd.nextDouble() - 0.5) * 40,
            lebenszeit: 0.4,
            maxLebenszeit: 0.4,
            farbe: const Color(0xFFFFB74D),
          ),
        );
      }
    }

    _partikel.removeWhere((p) => !p.update(dt));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Ausblick Band 4: Flame Game Loop'),
        backgroundColor: const Color(0xFF1E1B4B),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4338CA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_fps FPS',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final center = Offset(box.size.width / 2, 200);
                  final delta = details.localPosition - center;
                  setState(() {
                    _tiltX = (delta.dx / 120.0).clamp(-1.0, 1.0);
                    _tiltY = (delta.dy / 120.0).clamp(-1.0, 1.0);
                  });
                }
              },
              onPanEnd: (_) => setState(() {
                _tiltX = 0;
                _tiltY = 0;
              }),
              child: CustomPaint(
                painter: GamePainter(
                  schiff: _schiff,
                  partikel: _partikel,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      color: const Color(0xFF1E1B4B),
      child: const Row(
        children: [
          Icon(
            Icons.sports_esports,
            color: Color(0xFFA5B4FC),
            size: 28,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware-Beschleunigter Game Loop (Band 4)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFE0E7FF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ziehe mit Maus/Finger zum Lenken des Schiffs',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final RaumschiffComponent schiff;
  final List<Partikel> partikel;

  const GamePainter({
    required this.schiff,
    required this.partikel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sterne im Hintergrund zeichnen
    final starPaint = Paint()..color = Colors.white24;
    for (int i = 0; i < 30; i++) {
      final double sx = (i * 73) % size.width;
      final double sy = (i * 97) % size.height;
      final double r = (i % 2 == 0) ? 1.5 : 1.0;
      canvas.drawCircle(Offset(sx, sy), r, starPaint);
    }

    // Partikel zeichnen
    for (final p in partikel) {
      p.render(canvas);
    }

    // Raumschiff rendern
    schiff.render(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
