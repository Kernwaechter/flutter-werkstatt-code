import 'package:flutter/material.dart';

void main() => runApp(const Tag17App());

class Tag17App extends StatelessWidget {
  const Tag17App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: CustomPaint(
            size: const Size(200, 100),
            painter: HaubenPainter(),
          ),
        ),
      ),
    );
  }
}

class HaubenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const b = 110.0;
    final pos = Offset((size.width - b) / 2, size.height / 2);

    final schnee = Path()
      ..moveTo(pos.dx - 14, pos.dy)
      ..lineTo(pos.dx + b / 2, pos.dy - 37)
      ..lineTo(pos.dx + b + 14, pos.dy)
      ..lineTo(pos.dx + b + 14, pos.dy + 8)
      ..lineTo(pos.dx + b / 2, pos.dy - 28)
      ..lineTo(pos.dx - 14, pos.dy + 8)
      ..close();

    canvas.drawPath(schnee, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
