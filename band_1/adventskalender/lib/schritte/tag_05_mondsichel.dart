import 'package:flutter/material.dart';

void main() => runApp(const Tag05App());

class Tag05App extends StatelessWidget {
  const Tag05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF040714),
        body: Center(
          child: CustomPaint(
            size: const Size(200, 200),
            painter: MondPainter(),
          ),
        ),
      ),
    );
  }
}

class MondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final zentrum = Offset(size.width * 0.5, size.height * 0.5);

    final mond = Path()
      ..addOval(Rect.fromCircle(center: zentrum, radius: 45));

    final schatten = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(zentrum.dx - 16, zentrum.dy - 12),
        radius: 42,
      ));

    final sichel = Path.combine(
      PathOperation.difference,
      mond,
      schatten,
    );

    final paint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

    canvas.drawPath(sichel, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
