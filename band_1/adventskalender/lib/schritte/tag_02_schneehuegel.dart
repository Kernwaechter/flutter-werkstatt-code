import 'package:flutter/material.dart';

void main() => runApp(const Tag02App());

class Tag02App extends StatelessWidget {
  const Tag02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // Hintergrund
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF040714),
                    Color(0xFF0A132C),
                    Color(0xFF162544),
                  ],
                ),
              ),
            ),
            // Schneehügel
            Positioned.fill(
              child: CustomPaint(
                painter: SchneehuegelPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SchneehuegelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pfad = Path();
    pfad.moveTo(0, size.height * 0.72);

    pfad.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.65,
      size.width * 0.68,
      size.height * 0.74,
    );
    pfad.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.78,
      size.width,
      size.height * 0.70,
    );
    pfad.lineTo(size.width, size.height);
    pfad.lineTo(0, size.height);
    pfad.close();

    final farbe = Paint()..color = const Color(0xFF1E293B);
    canvas.drawPath(pfad, farbe);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
