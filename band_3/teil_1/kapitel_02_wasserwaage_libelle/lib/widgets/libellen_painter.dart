import 'dart:math' as math;
import 'package:flutter/material.dart';

class LibellenPainter extends CustomPainter {
  final double neigungX;
  final double neigungY;
  final bool istExakt;

  const LibellenPainter({
    required this.neigungX,
    required this.neigungY,
    required this.istExakt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 8;

    // 1. Äußerer Gehäusering
    final gehaeusePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, gehaeusePaint);

    final rahmenPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, maxRadius, rahmenPaint);

    // 2. Hilfskreise und Fadenkreuz
    final gitterPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, maxRadius * 0.66, gitterPaint);
    canvas.drawCircle(center, maxRadius * 0.33, gitterPaint);

    // Fadenkreuz
    canvas.drawLine(
      Offset(center.dx - maxRadius + 12, center.dy),
      Offset(center.dx + maxRadius - 12, center.dy),
      gitterPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius + 12),
      Offset(center.dx, center.dy + maxRadius - 12),
      gitterPaint,
    );

    // 3. Ziel-Toleranzkreis im Zentrum (grün oder rot)
    final zielFarbe = istExakt
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);

    final zielPaint = Paint()
      ..color = zielFarbe.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 28, zielPaint);

    final zielRandPaint = Paint()
      ..color = zielFarbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 28, zielRandPaint);

    // 4. Position der Luftblase berechnen
    // Skalierung: 1 Grad Neigung = ca. 5 Pixel Versatz
    final double rawDx = neigungY * 5.0;
    final double rawDy = neigungX * 5.0;

    final double distanz = math.sqrt(rawDx * rawDx + rawDy * rawDy);
    final double maxBlasenRadius = maxRadius - 26;

    double blasenDx = rawDx;
    double blasenDy = rawDy;

    if (distanz > maxBlasenRadius) {
      final double faktor = maxBlasenRadius / distanz;
      blasenDx = rawDx * faktor;
      blasenDy = rawDy * faktor;
    }

    final blasenCenter = Offset(
      center.dx + blasenDx,
      center.dy + blasenDy,
    );

    // 5. Luftblase zeichnen (mit Glanzpunkt)
    final blasenFarbe = istExakt
        ? const Color(0xFF10B981)
        : const Color(0xFF38BDF8);

    final blasenPaint = Paint()
      ..color = blasenFarbe.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(blasenCenter, 22, blasenPaint);

    final blasenRand = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(blasenCenter, 22, blasenRand);

    // Glanzlicht oben links
    final glanzPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(blasenCenter.dx - 6, blasenCenter.dy - 6),
      5,
      glanzPaint,
    );
  }

  @override
  bool shouldRepaint(covariant LibellenPainter oldDelegate) {
    return oldDelegate.neigungX != neigungX ||
        oldDelegate.neigungY != neigungY ||
        oldDelegate.istExakt != istExakt;
  }
}
