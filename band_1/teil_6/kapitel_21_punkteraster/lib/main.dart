import 'package:flutter/material.dart';

void main() {
  runApp(const KaesekaestchenApp());
}

// Größe des Spielfelds: 4 × 4 Kästchen, also 5 × 5 Punkte
const int zeilen = 4;
const int spalten = 4;

// Karopapier, Kugelschreiber-Blau und ein Textmarker
const Color papier = Color(0xFFFDFBF5);
const Color karoLinie = Color(0x3360A5FA);
const Color tinte = Color(0xFF1E3A8A);
const Color textmarker = Color(0xFFF59E0B);

// Eine Kante verbindet zwei benachbarte Punkte.
typedef Kante = ({bool waagerecht, int zeile, int spalte});

class Spielfeld {
  // Waagerechte Linien: 5 Reihen mit je 4 Linien
  final List<List<bool>> waagerecht = List.generate(
    zeilen + 1,
    (_) => List.filled(spalten, false),
  );

  // Senkrechte Linien: 4 Reihen mit je 5 Linien
  final List<List<bool>> senkrecht = List.generate(
    zeilen,
    (_) => List.filled(spalten + 1, false),
  );

  bool istGezogen(Kante kante) {
    if (kante.waagerecht) {
      return waagerecht[kante.zeile][kante.spalte];
    }
    return senkrecht[kante.zeile][kante.spalte];
  }

  void ziehe(Kante kante) {
    if (kante.waagerecht) {
      waagerecht[kante.zeile][kante.spalte] = true;
    } else {
      senkrecht[kante.zeile][kante.spalte] = true;
    }
  }

  int get anzahlGezogen {
    var summe = 0;
    for (final reihe in [...waagerecht, ...senkrecht]) {
      summe += reihe.where((gezogen) => gezogen).length;
    }
    return summe;
  }
}

// Rechnet zwischen Zeichenfläche und Spielfeld hin und her.
class Raster {
  static const double rand = 24;

  final double zelle;
  final Offset ursprung;

  Raster(Size groesse)
    : zelle = _zellenGroesse(groesse),
      ursprung = _linkeObereEcke(groesse);

  static double _zellenGroesse(Size groesse) {
    final breite = (groesse.width - 2 * rand) / spalten;
    final hoehe = (groesse.height - 2 * rand) / zeilen;
    return breite < hoehe ? breite : hoehe;
  }

  static Offset _linkeObereEcke(Size groesse) {
    final zelle = _zellenGroesse(groesse);
    return Offset(
      (groesse.width - zelle * spalten) / 2,
      (groesse.height - zelle * zeilen) / 2,
    );
  }

  // Wo liegt der Punkt in Zeile z und Spalte s?
  Offset punkt(int z, int s) {
    return ursprung + Offset(s * zelle, z * zelle);
  }

  // Anfang und Ende einer Kante auf der Zeichenfläche
  (Offset, Offset) enden(Kante kante) {
    final start = punkt(kante.zeile, kante.spalte);
    final ende = kante.waagerecht
        ? punkt(kante.zeile, kante.spalte + 1)
        : punkt(kante.zeile + 1, kante.spalte);
    return (start, ende);
  }

  // Alle Kanten des Spielfelds, waagerechte zuerst
  Iterable<Kante> get alleKanten sync* {
    for (var z = 0; z <= zeilen; z++) {
      for (var s = 0; s < spalten; s++) {
        yield (waagerecht: true, zeile: z, spalte: s);
      }
    }
    for (var z = 0; z < zeilen; z++) {
      for (var s = 0; s <= spalten; s++) {
        yield (waagerecht: false, zeile: z, spalte: s);
      }
    }
  }

  // Welche Kante liegt am nächsten an der Fingerspitze?
  Kante? kanteBei(Offset finger) {
    Kante? beste;
    var kleinsterAbstand = zelle * 0.35;
    for (final kante in alleKanten) {
      final (a, b) = enden(kante);
      final abstand = _abstandZurStrecke(finger, a, b);
      if (abstand < kleinsterAbstand) {
        kleinsterAbstand = abstand;
        beste = kante;
      }
    }
    return beste;
  }

  double _abstandZurStrecke(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final t =
        (ap.dx * ab.dx + ap.dy * ab.dy) /
        (ab.dx * ab.dx + ab.dy * ab.dy);
    final naechster = a + ab * t.clamp(0.0, 1.0);
    return (p - naechster).distance;
  }
}

class BrettPainter extends CustomPainter {
  final Spielfeld feld;
  final Kante? letzteKante;

  BrettPainter({required this.feld, required this.letzteKante});

  @override
  void paint(Canvas canvas, Size size) {
    final raster = Raster(size);

    // 1. Ebene: die Kanten
    for (final kante in raster.alleKanten) {
      final (start, ende) = raster.enden(kante);
      final istNeu = kante == letzteKante;
      final Color farbe;
      if (istNeu) {
        farbe = textmarker;
      } else if (feld.istGezogen(kante)) {
        farbe = tinte;
      } else {
        farbe = tinte.withValues(alpha: 0.08);
      }
      final stift = Paint()
        ..color = farbe
        ..strokeWidth = istNeu ? 8 : 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, ende, stift);
    }

    // 2. Ebene: die Punkte
    final punktFarbe = Paint()..color = tinte;
    for (var z = 0; z <= zeilen; z++) {
      for (var s = 0; s <= spalten; s++) {
        canvas.drawCircle(raster.punkt(z, s), 7, punktFarbe);
      }
    }
  }

  @override
  bool shouldRepaint(BrettPainter alt) => true;
}

class KaesekaestchenApp extends StatelessWidget {
  const KaesekaestchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Käsekästchen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: tinte),
        useMaterial3: true,
      ),
      home: const SpielSeite(),
    );
  }
}

class SpielSeite extends StatefulWidget {
  const SpielSeite({super.key});

  @override
  State<SpielSeite> createState() => _SpielSeiteState();
}

class _SpielSeiteState extends State<SpielSeite> {
  final Spielfeld _feld = Spielfeld();
  Kante? _letzteKante;

  void _brettGetippt(Offset finger, Size groesse) {
    final kante = Raster(groesse).kanteBei(finger);
    if (kante == null || _feld.istGezogen(kante)) return;

    setState(() {
      _feld.ziehe(kante);
      _letzteKante = kante;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: papier,
      appBar: AppBar(
        backgroundColor: papier,
        title: const Text('Käsekästchen'),
      ),
      body: Stack(
        children: [
          // Karopapier im Hintergrund
          const Positioned.fill(
            child: GridPaper(
              color: karoLinie,
              interval: 24,
              divisions: 1,
              subdivisions: 1,
              child: SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  '${_feld.anzahlGezogen} von '
                  '${(zeilen + 1) * spalten + zeilen * (spalten + 1)}'
                  ' Linien gezogen',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final groesse = constraints.biggest;
                      return GestureDetector(
                        onTapUp: (details) => _brettGetippt(
                          details.localPosition,
                          groesse,
                        ),
                        child: CustomPaint(
                          size: groesse,
                          painter: BrettPainter(
                            feld: _feld,
                            letzteKante: _letzteKante,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
