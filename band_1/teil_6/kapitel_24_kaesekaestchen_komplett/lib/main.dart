import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Ein ganz leichtes Grau statt reinem Weiß (Kapitel 4)
const Color karte = Color(0xFFF8FAFC);

// Eine Kante verbindet zwei benachbarte Punkte.
typedef Kante = ({bool waagerecht, int zeile, int spalte});

class Spieler {
  final String name;
  final String kuerzel;
  final Color hell;
  final Color dunkel;

  const Spieler({
    required this.name,
    required this.kuerzel,
    required this.hell,
    required this.dunkel,
  });
}

const Spieler rot = Spieler(
  name: 'Rot',
  kuerzel: 'R',
  hell: Color(0xFFFFE4E6),
  dunkel: Color(0xFF9F1239),
);

const Spieler blau = Spieler(
  name: 'Blau',
  kuerzel: 'B',
  hell: Color(0xFFE0F2FE),
  dunkel: Color(0xFF075985),
);

const Spieler computer = Spieler(
  name: 'Computer',
  kuerzel: 'C',
  hell: Color(0xFFE0F2FE),
  dunkel: Color(0xFF075985),
);

// Gegen wen spielst du?
enum Gegner { freund, leicht, mittel, schwer }

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

  // 0 = noch frei, 1 = gehört Spieler 1, 2 = gehört Spieler 2
  final List<List<int>> besitzer = List.generate(
    zeilen,
    (_) => List.filled(spalten, 0),
  );

  // Wie viele der vier Seiten eines Kästchens sind gezogen?
  int linienUm(int zeile, int spalte) {
    var anzahl = 0;
    if (waagerecht[zeile][spalte]) anzahl++; // oben
    if (waagerecht[zeile + 1][spalte]) anzahl++; // unten
    if (senkrecht[zeile][spalte]) anzahl++; // links
    if (senkrecht[zeile][spalte + 1]) anzahl++; // rechts
    return anzahl;
  }

  List<Kante> freieKanten() {
    final frei = <Kante>[];
    for (var z = 0; z <= zeilen; z++) {
      for (var s = 0; s < spalten; s++) {
        if (!waagerecht[z][s]) {
          frei.add((waagerecht: true, zeile: z, spalte: s));
        }
      }
    }
    for (var z = 0; z < zeilen; z++) {
      for (var s = 0; s <= spalten; s++) {
        if (!senkrecht[z][s]) {
          frei.add((waagerecht: false, zeile: z, spalte: s));
        }
      }
    }
    return frei;
  }

  // Die ein oder zwei Kästchen, die an einer Kante liegen
  List<(int, int)> nachbarn(Kante kante) {
    final liste = <(int, int)>[];
    if (kante.waagerecht) {
      if (kante.zeile > 0) {
        liste.add((kante.zeile - 1, kante.spalte)); // darüber
      }
      if (kante.zeile < zeilen) {
        liste.add((kante.zeile, kante.spalte)); // darunter
      }
    } else {
      if (kante.spalte > 0) {
        liste.add((kante.zeile, kante.spalte - 1)); // links
      }
      if (kante.spalte < spalten) {
        liste.add((kante.zeile, kante.spalte)); // rechts
      }
    }
    return liste;
  }

  // Zieht die Kante und meldet, wie viele Kästchen zugehen
  int ziehe(Kante kante, int spieler) {
    if (kante.waagerecht) {
      waagerecht[kante.zeile][kante.spalte] = true;
    } else {
      senkrecht[kante.zeile][kante.spalte] = true;
    }
    var geschlossen = 0;
    for (final (z, s) in nachbarn(kante)) {
      if (linienUm(z, s) == 4) {
        besitzer[z][s] = spieler;
        geschlossen++;
      }
    }
    return geschlossen;
  }

  int punkte(int spieler) {
    var summe = 0;
    for (final reihe in besitzer) {
      for (final wert in reihe) {
        if (wert == spieler) summe++;
      }
    }
    return summe;
  }

  bool get istVoll => punkte(1) + punkte(2) == zeilen * spalten;

  // --- Werkzeuge für den Computergegner ---

  // Macht diese Kante ein Kästchen zu?
  bool schliesstKaestchen(Kante kante) {
    for (final (z, s) in nachbarn(kante)) {
      if (linienUm(z, s) == 3) return true;
    }
    return false;
  }

  // Bekommt ein Kästchen durch diese Kante seine dritte Seite?
  bool schenktKaestchen(Kante kante) {
    for (final (z, s) in nachbarn(kante)) {
      if (linienUm(z, s) == 2) return true;
    }
    return false;
  }

  // Eine Kopie zum Ausprobieren, ohne das echte Spiel zu stören
  Spielfeld kopie() {
    final neu = Spielfeld();
    for (var z = 0; z < waagerecht.length; z++) {
      neu.waagerecht[z] = List.of(waagerecht[z]);
    }
    for (var z = 0; z < senkrecht.length; z++) {
      neu.senkrecht[z] = List.of(senkrecht[z]);
    }
    return neu;
  }

  // Wie viele Kästchen kann der Gegner nach dieser Kante
  // hintereinander einsammeln? Ausprobiert auf einer Kopie.
  int verlust(Kante kante) {
    final probe = kopie();
    probe.ziehe(kante, 1);
    var beute = 0;
    var weiter = true;
    while (weiter) {
      weiter = false;
      for (final k in probe.freieKanten()) {
        if (probe.schliesstKaestchen(k)) {
          beute += probe.ziehe(k, 2);
          weiter = true;
          break;
        }
      }
    }
    return beute;
  }
}

Kante waehleComputerZug(
  Spielfeld feld,
  Gegner stufe,
  math.Random zufall,
) {
  final frei = feld.freieKanten();

  // Regel 1: Schließt eine Kante ein Kästchen? Sofort nehmen!
  for (final kante in frei) {
    if (feld.schliesstKaestchen(kante)) return kante;
  }
  if (stufe == Gegner.leicht) {
    return frei[zufall.nextInt(frei.length)];
  }

  // Regel 2: Sichere Kanten verschenken nichts.
  final sicher = frei
      .where((kante) => !feld.schenktKaestchen(kante))
      .toList();
  if (sicher.isNotEmpty) {
    return sicher[zufall.nextInt(sicher.length)];
  }
  if (stufe == Gegner.mittel) {
    return frei[zufall.nextInt(frei.length)];
  }

  // Regel 3: Notlage – die Kante mit dem kleinsten Verlust
  var beste = frei.first;
  var kleinsterVerlust = feld.verlust(beste);
  for (final kante in frei) {
    final verlust = feld.verlust(kante);
    if (verlust < kleinsterVerlust) {
      beste = kante;
      kleinsterVerlust = verlust;
    }
  }
  return beste;
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
  final Spieler erster;
  final Spieler zweiter;
  final TextStyle schrift;
  final Kante? letzteKante;
  final List<(int, int)> neueKaestchen;
  final Animation<double> fortschritt;

  // repaint: Bei jedem Animationsschritt neu zeichnen
  BrettPainter({
    required this.feld,
    required this.erster,
    required this.zweiter,
    required this.schrift,
    required this.letzteKante,
    required this.neueKaestchen,
    required this.fortschritt,
  }) : super(repaint: fortschritt);

  @override
  void paint(Canvas canvas, Size size) {
    final raster = Raster(size);

    // 1. Ebene: die geschlossenen Kästchen
    for (var z = 0; z < zeilen; z++) {
      for (var s = 0; s < spalten; s++) {
        final nummer = feld.besitzer[z][s];
        if (nummer == 0) continue;
        final spieler = nummer == 1 ? erster : zweiter;
        final istNeu = neueKaestchen.contains((z, s));
        final skala = istNeu
            ? Curves.easeOutBack.transform(fortschritt.value)
            : 1.0;
        _malKaestchen(canvas, raster, z, s, spieler, skala);
      }
    }

    // 2. Ebene: die Kanten
    for (final kante in raster.alleKanten) {
      final (start, ziel) = raster.enden(kante);
      final istNeu = kante == letzteKante;
      // Die neue Linie wächst vom Startpunkt zum Endpunkt
      final ende = istNeu
          ? Offset.lerp(
              start,
              ziel,
              Curves.easeOut.transform(fortschritt.value),
            )!
          : ziel;
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

    // 3. Ebene: die Punkte
    final punktFarbe = Paint()..color = tinte;
    for (var z = 0; z <= zeilen; z++) {
      for (var s = 0; s <= spalten; s++) {
        canvas.drawCircle(raster.punkt(z, s), 7, punktFarbe);
      }
    }
  }

  void _malKaestchen(
    Canvas canvas,
    Raster raster,
    int z,
    int s,
    Spieler spieler,
    double skala,
  ) {
    final ecke = raster.punkt(z, s);
    final flaeche = RRect.fromRectAndRadius(
      (ecke & Size.square(raster.zelle)).deflate(8),
      const Radius.circular(6),
    );

    // Von der Mitte aus wachsen lassen
    canvas.save();
    canvas.translate(flaeche.center.dx, flaeche.center.dy);
    canvas.scale(skala);
    canvas.translate(-flaeche.center.dx, -flaeche.center.dy);
    canvas.drawRRect(flaeche, Paint()..color = spieler.hell);

    // Der Anfangsbuchstabe des Spielers in der Mitte
    final buchstabe = TextPainter(
      text: TextSpan(
        text: spieler.kuerzel,
        style: schrift.copyWith(
          fontSize: raster.zelle * 0.45,
          fontWeight: FontWeight.w900,
          color: spieler.dunkel,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    buchstabe.paint(
      canvas,
      flaeche.center -
          Offset(buchstabe.width / 2, buchstabe.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrettPainter alt) => true;
}

class PunkteKarte extends StatelessWidget {
  final Spieler spieler;
  final int punkte;
  final bool amZug;

  const PunkteKarte({
    super.key,
    required this.spieler,
    required this.punkte,
    required this.amZug,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: amZug ? spieler.hell : karte,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: amZug ? spieler.dunkel : const Color(0xFFCBD5E1),
          width: amZug ? 3 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: spieler.dunkel,
            child: Text(
              spieler.kuerzel,
              style: const TextStyle(
                color: karte,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              spieler.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            '$punkte',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: spieler.dunkel,
            ),
          ),
        ],
      ),
    );
  }
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

class _SpielSeiteState extends State<SpielSeite>
    with SingleTickerProviderStateMixin {
  Spielfeld _feld = Spielfeld();
  int _amZug = 1;
  Kante? _letzteKante;
  Gegner _gegner = Gegner.mittel;
  bool _computerDenkt = false;
  final math.Random _zufall = math.Random();

  // Das Uhrwerk für wachsende Linien und aufpoppende Kästchen
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  List<(int, int)> _neueKaestchen = [];

  // Deine Bilanz gegen den Computer
  int _siege = 0;
  int _niederlagen = 0;
  int _unentschieden = 0;

  // Ein eigener Player pro Geräusch
  final AudioPlayer _strichPlayer = AudioPlayer();
  final AudioPlayer _kaestchenPlayer = AudioPlayer();
  final AudioPlayer _endePlayer = AudioPlayer();

  Spieler get _zweiter => _gegner == Gegner.freund ? blau : computer;

  Spieler get _aktiver => _amZug == 1 ? rot : _zweiter;

  @override
  void initState() {
    super.initState();
    _ladeStatistik();
  }

  @override
  void dispose() {
    _animation.dispose();
    _strichPlayer.dispose();
    _kaestchenPlayer.dispose();
    _endePlayer.dispose();
    super.dispose();
  }

  Future<void> _ladeStatistik() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _siege = prefs.getInt('siege') ?? 0;
      _niederlagen = prefs.getInt('niederlagen') ?? 0;
      _unentschieden = prefs.getInt('unentschieden') ?? 0;
    });
  }

  Future<void> _speichereStatistik() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('siege', _siege);
    await prefs.setInt('niederlagen', _niederlagen);
    await prefs.setInt('unentschieden', _unentschieden);
  }

  Future<void> _spiele(AudioPlayer player, String datei) async {
    await player.stop();
    await player.play(AssetSource('sounds/$datei.wav'));
  }

  void _neuesSpiel() {
    setState(() {
      _feld = Spielfeld();
      _amZug = 1;
      _letzteKante = null;
      _neueKaestchen = [];
    });
  }

  void _gegnerGewaehlt(Set<Gegner> auswahl) {
    setState(() => _gegner = auswahl.first);
    _neuesSpiel();
  }

  void _brettGetippt(Offset finger, Size groesse) {
    if (_computerDenkt || _feld.istVoll) return;
    final kante = Raster(groesse).kanteBei(finger);
    if (kante == null || _feld.istGezogen(kante)) return;

    _zieheKante(kante);
    _computerZugFallsNoetig();
  }

  void _zieheKante(Kante kante) {
    var geschlossen = 0;
    setState(() {
      geschlossen = _feld.ziehe(kante, _amZug);
      _letzteKante = kante;
      // Welche Kästchen sind durch diese Linie gerade zugegangen?
      _neueKaestchen = [
        for (final (z, s) in _feld.nachbarn(kante))
          if (_feld.linienUm(z, s) == 4) (z, s),
      ];
      // Nur wer kein Kästchen schließt, gibt den Stift weiter
      if (geschlossen == 0) {
        _amZug = _amZug == 1 ? 2 : 1;
      }
    });
    _animation.forward(from: 0);

    // Rückmeldung für Ohren und Finger
    if (geschlossen > 0) {
      HapticFeedback.mediumImpact();
      _spiele(_kaestchenPlayer, 'kaestchen');
    } else {
      HapticFeedback.selectionClick();
      _spiele(_strichPlayer, 'strich');
    }

    if (_feld.istVoll) _spielZuEnde();
  }

  void _spielZuEnde() {
    final meine = _feld.punkte(1);
    final andere = _feld.punkte(2);
    final verloren = andere > meine;

    // Gegen einen Freund zählt keine Statistik
    if (_gegner == Gegner.freund) {
      _spiele(_endePlayer, 'sieg');
      return;
    }

    _spiele(_endePlayer, verloren ? 'schade' : 'sieg');
    setState(() {
      if (meine > andere) {
        _siege++;
      } else if (verloren) {
        _niederlagen++;
      } else {
        _unentschieden++;
      }
    });
    _speichereStatistik();
  }

  Future<void> _computerZugFallsNoetig() async {
    if (_gegner == Gegner.freund || _amZug != 2) return;
    setState(() => _computerDenkt = true);

    // Wer ein Kästchen schließt, darf noch einmal: darum while
    while (_amZug == 2 && !_feld.istVoll) {
      // Kurze Bedenkzeit, damit du den Zug mitverfolgen kannst
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      _zieheKante(waehleComputerZug(_feld, _gegner, _zufall));
    }

    setState(() => _computerDenkt = false);
  }

  @override
  Widget build(BuildContext context) {
    final vorbei = _feld.istVoll;

    return Scaffold(
      backgroundColor: papier,
      appBar: AppBar(
        backgroundColor: papier,
        title: const Text('Käsekästchen'),
        actions: [
          IconButton(
            tooltip: 'Neues Spiel',
            icon: const Icon(Icons.refresh),
            onPressed: _computerDenkt ? null : _neuesSpiel,
          ),
        ],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: PunkteKarte(
                          spieler: rot,
                          punkte: _feld.punkte(1),
                          amZug: !vorbei && _amZug == 1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PunkteKarte(
                          spieler: _zweiter,
                          punkte: _feld.punkte(2),
                          amZug: !vorbei && _amZug == 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Gegner>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: Gegner.freund,
                      label: Text('Zu zweit'),
                    ),
                    ButtonSegment(
                      value: Gegner.leicht,
                      label: Text('Leicht'),
                    ),
                    ButtonSegment(
                      value: Gegner.mittel,
                      label: Text('Mittel'),
                    ),
                    ButtonSegment(
                      value: Gegner.schwer,
                      label: Text('Schwer'),
                    ),
                  ],
                  selected: {_gegner},
                  onSelectionChanged: _computerDenkt
                      ? null
                      : _gegnerGewaehlt,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: vorbei
                      ? _baueErgebnis()
                      : Center(
                          child: Text(
                            '${_aktiver.name} ist am Zug',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
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
                            erster: rot,
                            zweiter: _zweiter,
                            schrift: Theme.of(context)
                                .textTheme
                                .bodyLarge!,
                            letzteKante: _letzteKante,
                            neueKaestchen: _neueKaestchen,
                            fortschritt: _animation,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_gegner != Gegner.freund)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Gegen den Computer: $_siege Siege · '
                      '$_niederlagen Niederlagen · '
                      '$_unentschieden Unentschieden',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _baueErgebnis() {
    final meine = _feld.punkte(1);
    final andere = _feld.punkte(2);

    final String ergebnis;
    if (meine > andere) {
      ergebnis = '${rot.name} gewinnt $meine : $andere!';
    } else if (andere > meine) {
      ergebnis = '${_zweiter.name} gewinnt $andere : $meine!';
    } else {
      ergebnis = 'Unentschieden $meine : $andere';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          ergebnis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tinte,
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: _neuesSpiel,
          icon: const Icon(Icons.replay),
          label: const Text('Noch eine Runde'),
        ),
      ],
    );
  }
}
