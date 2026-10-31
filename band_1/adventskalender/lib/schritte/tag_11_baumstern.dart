import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const Tag11App());

class Tag11App extends StatelessWidget {
  const Tag11App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: CustomPaint(
            size: const Size(150, 150),
            painter: SternPainter(),
          ),
        ),
      ),
    );
  }
}

class SternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final z = Offset(size.width / 2, size.height / 2);
    const aussenR = 30.0;
    const innenR = 13.0;

    final p = Path();
    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? aussenR : innenR;
      final w = (i * math.pi / 5) - (math.pi / 2);
      final px = z.dx + r * math.cos(w);
      final py = z.dy + r * math.sin(w);
      if (i == 0) p.moveTo(px, py);
      else p.lineTo(px, py);
    }
    p.close();

    final paint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
