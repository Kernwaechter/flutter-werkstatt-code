import 'package:flutter/material.dart';

void main() => runApp(const Tag07App());

class Tag07App extends StatelessWidget {
  const Tag07App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: CustomPaint(
            size: const Size(260, 260),
            painter: ChristbaumPainter(),
          ),
        ),
      ),
    );
  }
}

class ChristbaumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basis = Offset(size.width / 2, size.height * 0.85);

    // Stamm
    canvas.drawRect(
      Rect.fromLTWH(basis.dx - 12, basis.dy - 28, 24, 28),
      Paint()..color = const Color(0xFF78350F),
    );

    // 3 Etagen
    final etagen = [
      {'b': 140.0, 'h': 55.0, 'y': basis.dy - 22},
      {'b': 110.0, 'h': 50.0, 'y': basis.dy - 62},
      {'b': 80.0,  'h': 45.0, 'y': basis.dy - 100},
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
