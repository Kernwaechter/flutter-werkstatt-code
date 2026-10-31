import 'package:flutter/material.dart';

void main() => runApp(const Tag08App());

class Tag08App extends StatelessWidget {
  const Tag08App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: CustomPaint(
            size: const Size(260, 260),
            painter: KugelnPainter(),
          ),
        ),
      ),
    );
  }
}

class KugelnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basis = Offset(size.width / 2, size.height * 0.85);

    // Kugeln mit Glanzpunkt
    final kugeln = [
      Offset(basis.dx - 32, basis.dy - 40),
      Offset(basis.dx + 36, basis.dy - 45),
      Offset(basis.dx - 20, basis.dy - 80),
      Offset(basis.dx + 22, basis.dy - 85),
      Offset(basis.dx - 8,  basis.dy - 118),
    ];

    final kugelFarbe = Paint()..color = const Color(0xFFEF4444);
    final glanzFarbe = Paint()..color = Colors.white;

    for (final k in kugeln) {
      canvas.drawCircle(k, 6, kugelFarbe);
      canvas.drawCircle(
        Offset(k.dx - 1.8, k.dy - 1.8),
        1.6,
        glanzFarbe,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
