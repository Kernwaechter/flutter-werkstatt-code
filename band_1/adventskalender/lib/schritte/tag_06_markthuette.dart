import 'package:flutter/material.dart';

void main() => runApp(const Tag06App());

class Tag06App extends StatelessWidget {
  const Tag06App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: CustomPaint(
            size: const Size(200, 150),
            painter: HuettenPainter(),
          ),
        ),
      ),
    );
  }
}

class HuettenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const b = 110.0;
    const h = 75.0;
    final pos = Offset((size.width - b) / 2, (size.height - h) / 2);

    // Wand
    canvas.drawRect(
      Rect.fromLTWH(pos.dx, pos.dy, b, h),
      Paint()..color = const Color(0xFF78350F),
    );

    // Fenster
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + 20, pos.dy + 18, 32, 28),
      Paint()..color = const Color(0xFFFBBF24),
    );

    // Dach
    final dach = Path()
      ..moveTo(pos.dx - 12, pos.dy)
      ..lineTo(pos.dx + b / 2, pos.dy - 35)
      ..lineTo(pos.dx + b + 12, pos.dy)
      ..close();
    canvas.drawPath(dach, Paint()..color = const Color(0xFF451A03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
