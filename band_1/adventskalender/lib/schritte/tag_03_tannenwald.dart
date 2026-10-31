import 'package:flutter/material.dart';

void main() => runApp(const Tag03App());

class Tag03App extends StatelessWidget {
  const Tag03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CustomPaint(
          size: Size.infinite,
          painter: TannenwaldPainter(),
        ),
      ),
    );
  }
}

class TannenwaldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Himmel
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

    // 2. Hügel
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

    // 3. Tannenwald
    final waldFarbe = Paint()..color = const Color(0xFF0F172A);
    for (double x = 15; x < size.width; x += 52) {
      final th = 45.0 + ((x * 13) % 24);
      final yBase = size.height * 0.72;
      final tannenPfad = Path()
        ..moveTo(x, yBase - th)
        ..lineTo(x - 18, yBase)
        ..lineTo(x + 18, yBase)
        ..close();
      canvas.drawPath(tannenPfad, waldFarbe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
