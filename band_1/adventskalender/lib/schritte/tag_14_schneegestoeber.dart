import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const Tag14App());

class Tag14App extends StatefulWidget {
  const Tag14App({super.key});

  @override
  State<Tag14App> createState() => _Tag14AppState();
}

class Schneeflocke {
  double x, y, radius, geschwindigkeit;
  Schneeflocke(this.x, this.y, this.radius, this.geschwindigkeit);
}

class _Tag14AppState extends State<Tag14App>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<Schneeflocke> _flocken = [];
  final math.Random _zufall = math.Random(42);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 180; i++) {
      _flocken.add(Schneeflocke(
        _zufall.nextDouble() * 500,
        _zufall.nextDouble() * 800,
        1.2 + _zufall.nextDouble() * 2.5,
        1.0 + _zufall.nextDouble() * 1.5,
      ));
    }

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {
          for (final f in _flocken) {
            f.y += f.geschwindigkeit;
            if (f.y > 800) f.y = -10;
          }
        });
      });
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: CustomPaint(
          size: Size.infinite,
          painter: FlockenPainter(_flocken),
        ),
      ),
    );
  }
}

class FlockenPainter extends CustomPainter {
  final List<Schneeflocke> flocken;
  FlockenPainter(this.flocken);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    for (final f in flocken) {
      canvas.drawCircle(Offset(f.x, f.y), f.radius, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
