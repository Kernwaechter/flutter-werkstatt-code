import 'dart:math' as math;
import 'package:flutter/material.dart';

class EnergieTacho extends StatelessWidget {
  final double wertInWatt;
  final double maximalWert;

  const EnergieTacho({
    super.key,
    required this.wertInWatt,
    this.maximalWert = 5000.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: _TachoPainter(
          wert: wertInWatt.clamp(0.0, maximalWert),
          max: maximalWert,
        ),
      ),
    );
  }
}

class _TachoPainter extends CustomPainter {
  final double wert;
  final double max;

  _TachoPainter({required this.wert, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    // 1. Hintergrund-Bogen (grau)
    const startWinkel = math.pi * 0.75; // 135 Grad (unten links)
    const sweepWinkel = math.pi * 1.5; // 270 Grad Gesamtwinkel

    final bgPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startWinkel, sweepWinkel, false, bgPaint);

    // 2. Aktiver Bogen mit Farbverlauf
    final anteil = (wert / max).clamp(0.0, 1.0);
    final aktiverSweep = sweepWinkel * anteil;

    if (aktiverSweep > 0) {
      final aktivPaint = Paint()
        ..color = wert > 3500
            ? const Color(0xFFEF4444)
            : wert > 1500
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startWinkel, aktiverSweep, false, aktivPaint);
    }

    // 3. Skalenstriche
    final tickPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0;

    for (int i = 0; i <= 10; i++) {
      final tickWinkel = startWinkel + (sweepWinkel * (i / 10));
      final istHauptstrich = i % 2 == 0;
      final innenRadius = radius - (istHauptstrich ? 26 : 20);
      final aussenRadius = radius - 12;

      final p1 = Offset(
        center.dx + innenRadius * math.cos(tickWinkel),
        center.dy + innenRadius * math.sin(tickWinkel),
      );
      final p2 = Offset(
        center.dx + aussenRadius * math.cos(tickWinkel),
        center.dy + aussenRadius * math.sin(tickWinkel),
      );

      canvas.drawLine(
        p1,
        p2,
        tickPaint..strokeWidth = istHauptstrich ? 2.5 : 1.5,
      );
    }

    // 4. Zeiger
    final zeigerWinkel = startWinkel + (sweepWinkel * anteil);
    final zeigerLaenge = radius - 15;
    final zeigerSpitze = Offset(
      center.dx + zeigerLaenge * math.cos(zeigerWinkel),
      center.dy + zeigerLaenge * math.sin(zeigerWinkel),
    );

    final zeigerPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, zeigerSpitze, zeigerPaint);

    // 5. Nabe in der Mitte
    final nabenPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawCircle(center, 9.0, nabenPaint);
    final nabenRandPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, 9.0, nabenRandPaint);

    // 6. Textausgabe in der Mitte
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${wert.toInt()}\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const TextSpan(
            text: 'WATT',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy + 45,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TachoPainter oldDelegate) {
    return oldDelegate.wert != wert || oldDelegate.max != max;
  }
}
