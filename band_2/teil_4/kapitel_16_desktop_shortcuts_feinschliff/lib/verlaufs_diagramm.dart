import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/messwert.dart';

class VerlaufsDiagramm extends StatefulWidget {
  final List<Messwert> datenpunkte;

  const VerlaufsDiagramm({
    super.key,
    required this.datenpunkte,
  });

  @override
  State<VerlaufsDiagramm> createState() => _VerlaufsDiagrammState();
}

class _VerlaufsDiagrammState extends State<VerlaufsDiagramm> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.datenpunkte.isEmpty) {
      return const Center(child: Text('Keine Datenpunkte vorhanden'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            final x = event.localPosition.dx;
            final breite = constraints.maxWidth;
            final abstand = breite / (widget.datenpunkte.length - 1);
            final index = (x / abstand).round().clamp(
                  0,
                  widget.datenpunkte.length - 1,
                );
            if (index != _hoverIndex) {
              setState(() => _hoverIndex = index);
            }
          },
          onExit: (_) {
            setState(() => _hoverIndex = null);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _DiagrammPainter(
              daten: widget.datenpunkte,
              hoverIndex: _hoverIndex,
            ),
          ),
        );
      },
    );
  }
}

class _DiagrammPainter extends CustomPainter {
  final List<Messwert> daten;
  final int? hoverIndex;

  _DiagrammPainter({required this.daten, this.hoverIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (daten.length < 2) return;

    double maxWatt = daten.map((d) => d.watt).reduce(math.max);
    double minWatt = daten.map((d) => d.watt).reduce(math.min);

    // Schutz vor Division durch 0 (wenn alle Werte gleich sind)
    if (maxWatt == minWatt) {
      maxWatt += 100.0;
      minWatt = math.max(0.0, minWatt - 100.0);
    }

    const paddingUnten = 30.0;
    const paddingOben = 20.0;
    final zeichenHoehe = size.height - paddingUnten - paddingOben;
    final abstandX = size.width / (daten.length - 1);

    // 1. Horizontale Gitterlinien
    final gitterPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = paddingOben + (zeichenHoehe * (i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gitterPaint);
    }

    // 2. Pfade fuer Linie und gefuellte Flaeche
    final kurvenPfad = Path();
    final flaechenPfad = Path();

    final punkte = <Offset>[];

    for (int i = 0; i < daten.length; i++) {
      final x = i * abstandX;
      final anteilY = (daten[i].watt - minWatt) / (maxWatt - minWatt);
      final y = paddingOben + zeichenHoehe * (1.0 - anteilY);
      final punkt = Offset(x, y);
      punkte.add(punkt);

      if (i == 0) {
        kurvenPfad.moveTo(x, y);
        flaechenPfad.moveTo(x, size.height - paddingUnten);
        flaechenPfad.lineTo(x, y);
      } else {
        kurvenPfad.lineTo(x, y);
        flaechenPfad.lineTo(x, y);
      }
    }

    flaechenPfad.lineTo(size.width, size.height - paddingUnten);
    flaechenPfad.close();

    // 3. Flaeche mit Verlauf fuellen
    final verlauf = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0284C7).withValues(alpha: 0.4),
        const Color(0xFF0284C7).withValues(alpha: 0.0),
      ],
    );

    final flaechenPaint = Paint()
      ..shader = verlauf.createShader(
        Rect.fromLTWH(0, paddingOben, size.width, zeichenHoehe),
      );
    canvas.drawPath(flaechenPfad, flaechenPaint);

    // 4. Kurvenlinie zeichnen
    final liniePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(kurvenPfad, liniePaint);

    // 5. Datenpunkte zeichnen
    final punktPaint = Paint()..color = const Color(0xFF38BDF8);
    for (final p in punkte) {
      canvas.drawCircle(p, 3.5, punktPaint);
    }

    // 6. Hover-Hervorhebung
    if (hoverIndex != null &&
        hoverIndex! >= 0 &&
        hoverIndex! < punkte.length) {
      final hp = punkte[hoverIndex!];
      final item = daten[hoverIndex!];

      // Vertikale Hilfslinie
      final fadenkreuzPaint = Paint()
        ..color = const Color(0xFFF43F5E)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(hp.dx, paddingOben),
        Offset(hp.dx, size.height - paddingUnten),
        fadenkreuzPaint,
      );

      // Punkt hervorheben
      canvas.drawCircle(
        hp,
        6.5,
        Paint()..color = const Color(0xFFF43F5E),
      );
      canvas.drawCircle(
        hp,
        3.0,
        Paint()..color = Colors.white,
      );

      // Infobox zeichnen
      final text = '${item.zeitpunkt}\n${item.watt.toInt()} W';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      final boxBreite = tp.width + 16;
      final boxHoehe = tp.height + 8;
      double boxX = hp.dx - (boxBreite / 2);
      boxX = boxX.clamp(4.0, size.width - boxBreite - 4.0);
      final boxY = math.max(4.0, hp.dy - boxHoehe - 12);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxBreite, boxHoehe),
        const Radius.circular(6),
      );

      canvas.drawRRect(
        rrect,
        Paint()..color = const Color(0xFF0F172A),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFFF43F5E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      tp.paint(canvas, Offset(boxX + 8, boxY + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DiagrammPainter oldDelegate) {
    return oldDelegate.daten != daten || oldDelegate.hoverIndex != hoverIndex;
  }
}
