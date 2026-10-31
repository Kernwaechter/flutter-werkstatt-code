import 'package:flutter/material.dart';

void main() => runApp(const Tag10App());

class Tag10App extends StatelessWidget {
  const Tag10App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: CustomPaint(
            size: const Size(200, 100),
            painter: MarkisenPainter(),
          ),
        ),
      ),
    );
  }
}

class MarkisenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const b = 120.0;
    const streifen = 6;
    final w = b / streifen;
    final start = Offset((size.width - b) / 2, size.height / 2);

    for (int i = 0; i < streifen; i++) {
      final x = start.dx + i * w;
      final c = (i % 2 == 0) ? const Color(0xFFDC2626) : Colors.white;

      final p = Path()
        ..moveTo(x, start.dy)
        ..lineTo(x + w, start.dy)
        ..lineTo(x + w - 3, start.dy + 16)
        ..lineTo(x - 3, start.dy + 16)
        ..close();

      canvas.drawPath(p, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
