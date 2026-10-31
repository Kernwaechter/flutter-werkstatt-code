import 'dart:math' as math;
import 'package:flutter/material.dart';

class RecLevelPoti extends StatelessWidget {
  final double wert; // 0.0 bis 1.0
  final ValueChanged<double> onChanged;

  const RecLevelPoti({
    super.key,
    required this.wert,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'REC LEVEL',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final delta = -details.primaryDelta! / 100.0;
            onChanged((wert + delta).clamp(0.0, 1.0));
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF272B34),
              border: Border.all(color: const Color(0xFF475569), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _PotiPainter(wert: wert),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(wert * 10).toStringAsFixed(1)}',
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PotiPainter extends CustomPainter {
  final double wert;

  _PotiPainter({required this.wert});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Winkel von 135 Grad bis 405 Grad (270 Grad Drehung)
    final winkel = (math.pi * 0.75) + (math.pi * 1.5 * wert);

    // Zeigerlinie auf dem Drehknopf
    final zeigerStart = Offset(
      center.dx + 8 * math.cos(winkel),
      center.dy + 8 * math.sin(winkel),
    );
    final zeigerEnde = Offset(
      center.dx + 24 * math.cos(winkel),
      center.dy + 24 * math.sin(winkel),
    );

    final p = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(zeigerStart, zeigerEnde, p);
  }

  @override
  bool shouldRepaint(covariant _PotiPainter oldDelegate) {
    return oldDelegate.wert != wert;
  }
}
