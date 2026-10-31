import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const Tag21App());

class Tag21App extends StatelessWidget {
  const Tag21App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: CustomPaint(
            size: const Size(120, 120),
            painter: TurmuhrPainter(),
          ),
        ),
      ),
    );
  }
}

class TurmuhrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final z = Offset(size.width / 2, size.height / 2);
    // Zifferblatt
    final zifferFarbe = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawCircle(z, 30, zifferFarbe);

    // Zeiger für 10:10 Uhr
    const stdWinkel = (10 * 30 * math.pi / 180) - (math.pi / 2);
    const minWinkel = (10 * 6 * math.pi / 180) - (math.pi / 2);

    final zeiger = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5;

    canvas.drawLine(
      z,
      Offset(
        z.dx + 16 * math.cos(stdWinkel),
        z.dy + 16 * math.sin(stdWinkel),
      ),
      zeiger,
    );
    canvas.drawLine(
      z,
      Offset(
        z.dx + 22 * math.cos(minWinkel),
        z.dy + 22 * math.sin(minWinkel),
      ),
      zeiger,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
