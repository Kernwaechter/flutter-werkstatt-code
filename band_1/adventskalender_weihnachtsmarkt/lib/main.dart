import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const WeihnachtsApp());
}

class WeihnachtsApp extends StatelessWidget {
  const WeihnachtsApp({super.key});

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

/// Datenmodell für eine einzelne fallende Schneeflocke
class Schneeflocke {
  double x;
  double y;
  double radius;
  double geschwindigkeit;
  double taumelPhase;

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
  late AnimationController _controller;
  final List<Schneeflocke> _flocken = [];
  final math.Random _zufall = math.Random(42);

  double _windVersatz = 0.0;
  bool _schneesturm = false;
  double _zeit = 0.0;

  @override
  void initState() {
    super.initState();
    _initialisiereFlocken(180);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_aktualisiereSzene);

    _controller.repeat();
  }

  void _initialisiereFlocken(int anzahl) {
    _flocken.clear();
    for (int i = 0; i < anzahl; i++) {
      _flocken.add(
        Schneeflocke(
          x: _zufall.nextDouble() * 1000,
          y: _zufall.nextDouble() * 800,
          radius: 1.2 + _zufall.nextDouble() * 2.8,
          geschwindigkeit: 0.8 + _zufall.nextDouble() * 1.8,
          taumelPhase: _zufall.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  void _aktualisiereSzene() {
    setState(() {
      _zeit += 0.03;
      final tempoFaktor = _schneesturm ? 3.2 : 1.0;
      final sturmDrift = _schneesturm ? 2.5 : 0.0;

      for (final f in _flocken) {
        f.y += f.geschwindigkeit * tempoFaktor;
        f.x += math.sin(f.taumelPhase + _zeit) * 0.8 +
            _windVersatz * 0.15 +
            sturmDrift;

        if (f.y > 800) {
          f.y = -10;
          f.x = _zufall.nextDouble() * 1000;
        }
        if (f.x > 1050) f.x = -20;
        if (f.x < -20) f.x = 1050;
      }

      // Wind klingt langsam wieder ab
      _windVersatz *= 0.94;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _windVersatz += details.delta.dx * 0.4;
          });
        },
        child: Stack(
          children: [
            // Der gemalte Markt
            Positioned.fill(
              child: CustomPaint(
                painter: WeihnachtsMarktPainter(
                  flocken: _flocken,
                  pulsation: _controller.value,
                  zeit: _zeit,
                ),
              ),
            ),

            // Obere Steuerung & Gruß
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD97706),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFBBF24),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Frohe Weihnachten & Gut Code!',
                            style: TextStyle(
                              color: Color(0xFFFEF3C7),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _schneesturm
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      icon: Icon(
                        _schneesturm ? Icons.cyclone : Icons.ac_unit,
                        size: 18,
                      ),
                      label: Text(
                        _schneesturm
                            ? 'Sturm aktiv!'
                            : 'Schneesturm an',
                      ),
                      onPressed: () {
                        setState(() {
                          _schneesturm = !_schneesturm;
                          if (_schneesturm) {
                            _initialisiereFlocken(360);
                          } else {
                            _initialisiereFlocken(180);
                          }
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

/// Der Painter, der alle 24 Stufen zu einem Bild vereint
class WeihnachtsMarktPainter extends CustomPainter {
  final List<Schneeflocke> flocken;
  final double pulsation;
  final double zeit;

  WeihnachtsMarktPainter({
    required this.flocken,
    required this.pulsation,
    required this.zeit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Himmel
    final himmelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040714),
          Color(0xFF0A132C),
          Color(0xFF162544),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      himmelPaint,
    );

    // 2. Sterne
    final sternePaint =
        Paint()..color = Colors.white.withValues(alpha: 0.85);
    final sternZufall = math.Random(101);
    for (int i = 0; i < 40; i++) {
      final sx = sternZufall.nextDouble() * size.width;
      final sy = sternZufall.nextDouble() * (size.height * 0.5);
      final r = 0.8 + sternZufall.nextDouble() * 1.5;
      final f = (math.sin(zeit * 2 + i) + 1) / 2;
      sternePaint.color = Colors.white.withValues(alpha: 0.3 + 0.6 * f);
      canvas.drawCircle(Offset(sx, sy), r, sternePaint);
    }

    // 3. Mondsichel
    final mondPfad = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.16),
          radius: 26,
        ),
      );
    final schattenPfad = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.82 - 9, size.height * 0.16 - 7),
          radius: 24,
        ),
      );
    final sichel = Path.combine(
      PathOperation.difference,
      mondPfad,
      schattenPfad,
    );
    final mondFarbe = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawPath(sichel, mondFarbe);

    // 4. Schneehügel im Hintergrund
    final huegelPfad = Path();
    huegelPfad.moveTo(0, size.height * 0.72);
    huegelPfad.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.65,
      size.width * 0.68,
      size.height * 0.74,
    );
    huegelPfad.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.78,
      size.width,
      size.height * 0.70,
    );
    huegelPfad.lineTo(size.width, size.height);
    huegelPfad.lineTo(0, size.height);
    huegelPfad.close();

    final huegelPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawPath(huegelPfad, huegelPaint);

    // 5. Tannenwald-Silhouetten
    final waldFarbe = Paint()..color = const Color(0xFF0F172A);
    for (double x = 20; x < size.width; x += 55) {
      final th = 45.0 + ((x * 13) % 25);
      final yBase = size.height * 0.72;
      final tannenPfad = Path()
        ..moveTo(x, yBase - th)
        ..lineTo(x - 18, yBase)
        ..lineTo(x + 18, yBase)
        ..close();
      canvas.drawPath(tannenPfad, waldFarbe);
    }

    // 6. Vorderer Schneeboden
    final bodenPfad = Path()
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
    final bodenFarbe = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawPath(bodenPfad, bodenFarbe);

    // 7. Gemütliche Markthütten links und rechts
    _zeichneHuette(canvas, Offset(size.width * 0.12, size.height * 0.70));
    _zeichneHuette(canvas, Offset(size.width * 0.76, size.height * 0.70));

    // 8. Großer festlicher Christbaum im Zentrum
    _zeichneChristbaum(
      canvas,
      Offset(size.width * 0.48, size.height * 0.78),
    );

    // 9. Schneeflocken zeichnen
    final flockenFarbe = Paint()..color = Colors.white;
    for (final f in flocken) {
      flockenFarbe.color = Colors.white.withValues(
        alpha: (0.4 + (f.radius / 4.0) * 0.6).clamp(0.0, 1.0),
      );
      canvas.drawCircle(Offset(f.x, f.y), f.radius, flockenFarbe);
    }
  }

  void _zeichneHuette(Canvas canvas, Offset pos) {
    const b = 110.0;
    const h = 75.0;

    // Holzwände
    final wand = Paint()..color = const Color(0xFF78350F);
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, b, h), wand);

    // Warmes Fensterlicht
    final fenster = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + 20, pos.dy + 18, 32, 28),
      fenster,
    );

    // Giebeldach
    final dach = Path()
      ..moveTo(pos.dx - 12, pos.dy)
      ..lineTo(pos.dx + b / 2, pos.dy - 35)
      ..lineTo(pos.dx + b + 12, pos.dy)
      ..close();
    final dachFarbe = Paint()..color = const Color(0xFF451A03);
    canvas.drawPath(dach, dachFarbe);

    // Schnee auf dem Dach
    final schneeDach = Path()
      ..moveTo(pos.dx - 14, pos.dy)
      ..lineTo(pos.dx + b / 2, pos.dy - 37)
      ..lineTo(pos.dx + b + 14, pos.dy)
      ..lineTo(pos.dx + b + 14, pos.dy + 8)
      ..lineTo(pos.dx + b / 2, pos.dy - 28)
      ..lineTo(pos.dx - 14, pos.dy + 8)
      ..close();
    canvas.drawPath(schneeDach, Paint()..color = Colors.white);
  }

  void _zeichneChristbaum(Canvas canvas, Offset basis) {
    // Stamm
    final stammFarbe = Paint()..color = const Color(0xFF78350F);
    canvas.drawRect(
      Rect.fromLTWH(basis.dx - 12, basis.dy - 30, 24, 30),
      stammFarbe,
    );

    // 3 Tannenetagen
    final tannenGruen = Paint()..color = const Color(0xFF065F46);
    final etagen = [
      {'breite': 140.0, 'hoehe': 55.0, 'y': basis.dy - 25},
      {'breite': 110.0, 'hoehe': 50.0, 'y': basis.dy - 65},
      {'breite': 80.0, 'hoehe': 45.0, 'y': basis.dy - 105},
    ];

    for (final e in etagen) {
      final pfad = Path()
        ..moveTo(basis.dx, e['y']! - e['hoehe']!)
        ..lineTo(basis.dx - e['breite']! / 2, e['y']!)
        ..lineTo(basis.dx + e['breite']! / 2, e['y']!)
        ..close();
      canvas.drawPath(pfad, tannenGruen);
    }

    // Baumkugeln & pulsierende Lichter
    final kugeln = [
      Offset(basis.dx - 35, basis.dy - 40),
      Offset(basis.dx + 42, basis.dy - 45),
      Offset(basis.dx - 22, basis.dy - 85),
      Offset(basis.dx + 26, basis.dy - 90),
      Offset(basis.dx - 8, basis.dy - 125),
    ];

    final kugelFarbe = Paint()..color = const Color(0xFFEF4444);
    for (final k in kugeln) {
      canvas.drawCircle(k, 5, kugelFarbe);
      // Glanzpunkt
      canvas.drawCircle(
        Offset(k.dx - 1.5, k.dy - 1.5),
        1.5,
        Paint()..color = Colors.white,
      );
    }

    // Goldener Stern an der Spitze
    final sternSpitze = Offset(basis.dx, basis.dy - 155);
    final sternPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.solid,
        1.5 + pulsation * 2.5,
      );

    _zeichneStern(canvas, sternSpitze, 14, 6, sternPaint);
  }

  void _zeichneStern(
    Canvas canvas,
    Offset zentrum,
    double aussenR,
    double innenR,
    Paint paint,
  ) {
    final pfad = Path();
    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? aussenR : innenR;
      final winkel = (i * math.pi / 5) - (math.pi / 2);
      final x = zentrum.dx + r * math.cos(winkel);
      final y = zentrum.dy + r * math.sin(winkel);
      if (i == 0) {
        pfad.moveTo(x, y);
      } else {
        pfad.lineTo(x, y);
      }
    }
    pfad.close();
    canvas.drawPath(pfad, paint);
  }

  @override
  bool shouldRepaint(covariant WeihnachtsMarktPainter oldDelegate) =>
      true;
}
