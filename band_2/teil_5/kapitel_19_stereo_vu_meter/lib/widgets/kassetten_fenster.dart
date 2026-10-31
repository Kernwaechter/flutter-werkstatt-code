import 'dart:math' as math;
import 'package:flutter/material.dart';

class KassettenFenster extends StatelessWidget {
  final double bandFortschritt; // 0.0 (ganz links) bis 1.0 (ganz rechts)
  final double rotationsWinkel; // Laufender Rotationswinkel in Radiant
  final String mixtapeTitel;
  final String bandTyp;

  const KassettenFenster({
    super.key,
    required this.bandFortschritt,
    required this.rotationsWinkel,
    this.mixtapeTitel = 'FREITAGABEND RADIO-MIX 86',
    this.bandTyp = 'CrO2 II',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF475569), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          size: Size.infinite,
          painter: _KassettenPainter(
            fortschritt: bandFortschritt.clamp(0.0, 1.0),
            winkel: rotationsWinkel,
            titel: mixtapeTitel,
            typ: bandTyp,
          ),
        ),
      ),
    );
  }
}

class _KassettenPainter extends CustomPainter {
  final double fortschritt;
  final double winkel;
  final String titel;
  final String typ;

  _KassettenPainter({
    required this.fortschritt,
    required this.winkel,
    required this.titel,
    required this.typ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Hintergrundbeleuchtung des Fachs
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E232B), Color(0xFF101318)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Kassetten-Gehaeuse (Anthrazit/Rauchglas)
    final kWidth = math.min(size.width - 40, 480.0);
    final kHeight = 180.0;
    final kRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: kWidth,
      height: kHeight,
    );

    final gehaeusePaint = Paint()
      ..color = const Color(0xFF1F242D)
      ..style = PaintingStyle.fill;
    final gehaeuseRand = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(kRect, const Radius.circular(8)),
      gehaeusePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(kRect, const Radius.circular(8)),
      gehaeuseRand,
    );

    // 3. Kassetten-Aufkleber / Etikett (Gold/Bernstein)
    final labelRect = Rect.fromCenter(
      center: Offset(cx, cy - 35),
      width: kWidth - 50,
      height: 48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFB45309),
    );

    // Text auf dem Etikett
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$titel  ·  [$typ]',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: kWidth - 60);
    textPainter.paint(
      canvas,
      Offset(cx - (textPainter.width / 2), cy - 42),
    );

    // 4. Sichtfenster in der Mitte des Etiketts
    final fensterRect = Rect.fromCenter(
      center: Offset(cx, cy + 20),
      width: kWidth - 80,
      height: 70,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fensterRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF0F1115),
    );

    // 5. Spulenpositionen
    final spulenAbstand = kWidth * 0.22;
    final spuleLinks = Offset(cx - spulenAbstand, cy + 20);
    final spuleRechts = Offset(cx + spulenAbstand, cy + 20);

    // Dynamische Radien der Bandwickel
    const rMin = 22.0;
    const rMax = 44.0;
    final rLinks = rMin + (rMax - rMin) * (1.0 - fortschritt);
    final rRechts = rMin + (rMax - rMin) * fortschritt;

    // Braunes Magnetband auf den Spulen
    final bandPaint = Paint()..color = const Color(0xFF5A2A18);
    canvas.drawCircle(spuleLinks, rLinks, bandPaint);
    canvas.drawCircle(spuleRechts, rRechts, bandPaint);

    // Magnetband-Fuehrung unten
    canvas.drawLine(
      Offset(spuleLinks.dx, cy + 45),
      Offset(spuleRechts.dx, cy + 45),
      Paint()
        ..color = const Color(0xFF5A2A18)
        ..strokeWidth = 4.0,
    );

    // Tonkopf-Schacht-Attrappe unten
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + 45),
          width: 50,
          height: 12,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF334155),
    );

    // 6. Die beiden weissen Spulenkerne mit 6 Zaehnen zeichnen
    _zeichneSpulenkern(canvas, spuleLinks, winkel);
    _zeichneSpulenkern(canvas, spuleRechts, winkel);
  }

  void _zeichneSpulenkern(Canvas canvas, Offset center, double w) {
    // Weisser Kunststoffkern
    canvas.drawCircle(
      center,
      18.0,
      Paint()..color = const Color(0xFFE2E8F0),
    );
    // Zentrierloch
    canvas.drawCircle(
      center,
      8.0,
      Paint()..color = const Color(0xFF0F1115),
    );

    // 6 Zaehne
    final zahnPaint = Paint()..color = const Color(0xFF0F1115);
    for (int i = 0; i < 6; i++) {
      final zWinkel = w + (i * (math.pi / 3));
      final zx = center.dx + 12.0 * math.cos(zWinkel);
      final zy = center.dy + 12.0 * math.sin(zWinkel);
      canvas.drawCircle(Offset(zx, zy), 2.5, zahnPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KassettenPainter oldDelegate) {
    return oldDelegate.fortschritt != fortschritt ||
        oldDelegate.winkel != winkel ||
        oldDelegate.titel != titel;
  }
}
