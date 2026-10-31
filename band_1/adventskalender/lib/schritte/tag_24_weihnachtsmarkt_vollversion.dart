import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const Tag24App());

class Tag24App extends StatelessWidget {
  const Tag24App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Der leuchtende Weihnachtsmarkt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WeihnachtsMarktBlick(),
    );
  }
}

class Schneeflocke {
  double x, y, radius, geschwindigkeit, taumelPhase;
  Schneeflocke({
    required this.x,
    required this.y,
    required this.radius,
    required this.geschwindigkeit,
    required this.taumelPhase,
  });
}

class WeihnachtsMarktBlick extends StatefulWidget {
  const WeihnachtsMarktBlick({super.key});

  @override
  State<WeihnachtsMarktBlick> createState() =>
      _WeihnachtsMarktBlickState();
}

class _WeihnachtsMarktBlickState extends State<WeihnachtsMarktBlick>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<Schneeflocke> _flocken = [];
  final math.Random _zufall = math.Random(42);
  double _wind = 0.0;
  bool _sturm = false;
  double _zeit = 0.0;

  @override
  void initState() {
    super.initState();
    _initFlocken(180);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_tick);
    _ctrl.repeat();
  }

  void _initFlocken(int n) {
    _flocken.clear();
    for (int i = 0; i < n; i++) {
      _flocken.add(Schneeflocke(
        x: _zufall.nextDouble() * 1000,
        y: _zufall.nextDouble() * 800,
        radius: 1.2 + _zufall.nextDouble() * 2.8,
        geschwindigkeit: 0.8 + _zufall.nextDouble() * 1.8,
        taumelPhase: _zufall.nextDouble() * 2 * math.pi,
      ));
    }
  }

  void _tick() {
    setState(() {
      _zeit += 0.03;
      final fkt = _sturm ? 3.2 : 1.0;
      final drift = _sturm ? 2.5 : 0.0;

      for (final f in _flocken) {
        f.y += f.geschwindigkeit * fkt;
        f.x += math.sin(f.taumelPhase + _zeit) * 0.8 +
            _wind * 0.15 +
            drift;

        if (f.y > 800) {
          f.y = -10;
          f.x = _zufall.nextDouble() * 1000;
        }
        if (f.x > 1050) f.x = -20;
        if (f.x < -20) f.x = 1050;
      }
      _wind *= 0.94;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: GestureDetector(
        onPanUpdate: (d) => setState(() => _wind += d.delta.dx * 0.4),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MarktPainter(
                  flocken: _flocken,
                  pulsation: _ctrl.value,
                  zeit: _zeit,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      child: const Text(
                        'Frohe Weihnachten & Gut Code!',
                        style: TextStyle(
                          color: Color(0xFFFEF3C7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sturm
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _sturm ? Icons.cyclone : Icons.ac_unit,
                      ),
                      label: Text(
                        _sturm ? 'Sturm aktiv' : 'Sturm an',
                      ),
                      onPressed: () {
                        setState(() {
                          _sturm = !_sturm;
                          _initFlocken(_sturm ? 360 : 180);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarktPainter extends CustomPainter {
  final List<Schneeflocke> flocken;
  final double pulsation;
  final double zeit;

  MarktPainter({
    required this.flocken,
    required this.pulsation,
    required this.zeit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Himmel
    final himmel = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF040714), Color(0xFF162544)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      himmel,
    );

    // Hügel
    final huegel = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.65,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(huegel, Paint()..color = const Color(0xFF1E293B));

    // Boden
    final boden = Path()
      ..moveTo(0, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.75,
        size.width,
        size.height * 0.80,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(boden, Paint()..color = const Color(0xFFE2E8F0));

    // Hütte
    _huette(canvas, Offset(size.width * 0.12, size.height * 0.70));
    _huette(canvas, Offset(size.width * 0.76, size.height * 0.70));

    // Baum
    _baum(canvas, Offset(size.width * 0.48, size.height * 0.78));

    // Flocken
    final fp = Paint()..color = Colors.white;
    for (final f in flocken) {
      fp.color = Colors.white.withValues(
        alpha: (0.4 + (f.radius / 4.0) * 0.6).clamp(0.0, 1.0),
      );
      canvas.drawCircle(Offset(f.x, f.y), f.radius, fp);
    }
  }

  void _huette(Canvas canvas, Offset p) {
    const b = 110.0;
    const h = 75.0;
    canvas.drawRect(
      Rect.fromLTWH(p.dx, p.dy, b, h),
      Paint()..color = const Color(0xFF78350F),
    );
    canvas.drawRect(
      Rect.fromLTWH(p.dx + 20, p.dy + 18, 32, 28),
      Paint()..color = const Color(0xFFFBBF24),
    );
    final dach = Path()
      ..moveTo(p.dx - 12, p.dy)
      ..lineTo(p.dx + b / 2, p.dy - 35)
      ..lineTo(p.dx + b + 12, p.dy)
      ..close();
    canvas.drawPath(dach, Paint()..color = const Color(0xFF451A03));

    final schnee = Path()
      ..moveTo(p.dx - 14, p.dy)
      ..lineTo(p.dx + b / 2, p.dy - 37)
      ..lineTo(p.dx + b + 14, p.dy)
      ..lineTo(p.dx + b + 14, p.dy + 8)
      ..lineTo(p.dx + b / 2, p.dy - 28)
      ..lineTo(p.dx - 14, p.dy + 8)
      ..close();
    canvas.drawPath(schnee, Paint()..color = Colors.white);
  }

  void _baum(Canvas canvas, Offset basis) {
    canvas.drawRect(
      Rect.fromLTWH(basis.dx - 12, basis.dy - 30, 24, 30),
      Paint()..color = const Color(0xFF78350F),
    );

    final etagen = [
      {'b': 140.0, 'h': 55.0, 'y': basis.dy - 25},
      {'b': 110.0, 'h': 50.0, 'y': basis.dy - 65},
      {'b': 80.0,  'h': 45.0, 'y': basis.dy - 105},
    ];

    final gruen = Paint()..color = const Color(0xFF065F46);
    for (final e in etagen) {
      final p = Path()
        ..moveTo(basis.dx, e['y']! - e['h']!)
        ..lineTo(basis.dx - e['b']! / 2, e['y']!)
        ..lineTo(basis.dx + e['b']! / 2, e['y']!)
        ..close();
      canvas.drawPath(p, gruen);
    }

    final kugeln = [
      Offset(basis.dx - 35, basis.dy - 40),
      Offset(basis.dx + 42, basis.dy - 45),
      Offset(basis.dx - 22, basis.dy - 85),
      Offset(basis.dx + 26, basis.dy - 90),
    ];
    for (final k in kugeln) {
      final kp = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(k, 5, kp);
    }

    // Stern
    final sz = Offset(basis.dx, basis.dy - 155);
    final sternPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.solid,
        1.5 + pulsation * 2.5,
      );

    final sp = Path();
    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? 14.0 : 6.0;
      final w = (i * math.pi / 5) - (math.pi / 2);
      final x = sz.dx + r * math.cos(w);
      final y = sz.dy + r * math.sin(w);
      if (i == 0) sp.moveTo(x, y);
      else sp.lineTo(x, y);
    }
    sp.close();
    canvas.drawPath(sp, sternPaint);
  }

  @override
  bool shouldRepaint(covariant MarktPainter oldDelegate) => true;
}
