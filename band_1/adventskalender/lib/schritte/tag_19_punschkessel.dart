import 'package:flutter/material.dart';

void main() => runApp(const Tag19App());

class Tag19App extends StatelessWidget {
  const Tag19App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: CustomPaint(
            size: const Size(120, 120),
            painter: KesselPainter(),
          ),
        ),
      ),
    );
  }
}

class KesselPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final z = Offset(size.width / 2, size.height * 0.7);

    // Kupferner Kessel
    final kesselPaint = Paint()..color = const Color(0xFFB45309);
    canvas.drawCircle(z, 28, kesselPaint);

    // Dampf
    final dampf = Paint()
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(z.dx - 4, z.dy - 35), 6, dampf);
    canvas.drawCircle(Offset(z.dx + 6, z.dy - 48), 9, dampf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
