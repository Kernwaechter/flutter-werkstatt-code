import 'package:flutter/material.dart';
import 'schritte/tag_01_mitternachtshimmel.dart' as t01;
import 'schritte/tag_02_schneehuegel.dart' as t02;
import 'schritte/tag_03_tannenwald.dart' as t03;
import 'schritte/tag_04_sternenhimmel.dart' as t04;
import 'schritte/tag_05_mondsichel.dart' as t05;
import 'schritte/tag_06_markthuette.dart' as t06;
import 'schritte/tag_07_christbaum.dart' as t07;
import 'schritte/tag_08_baumkugeln.dart' as t08;
import 'schritte/tag_09_lichterkette.dart' as t09;
import 'schritte/tag_10_streifenmarkise.dart' as t10;
import 'schritte/tag_11_baumstern.dart' as t11;
import 'schritte/tag_12_responsives_layout.dart' as t12;
import 'schritte/tag_13_schneeflocke_modell.dart' as t13;
import 'schritte/tag_14_schneegestoeber.dart' as t14;
import 'schritte/tag_15_winterwind.dart' as t15;
import 'schritte/tag_16_interaktiver_wind.dart' as t16;
import 'schritte/tag_17_schneehauben.dart' as t17;
import 'schritte/tag_18_festliche_akustik.dart' as t18;
import 'schritte/tag_19_punschkessel.dart' as t19;
import 'schritte/tag_20_kaminfeuer.dart' as t20;
import 'schritte/tag_21_turmuhr.dart' as t21;
import 'schritte/tag_22_schneesturm_schalter.dart' as t22;
import 'schritte/tag_23_gold_typografie.dart' as t23;
import 'schritte/tag_24_weihnachtsmarkt_vollversion.dart' as t24;

void main() {
  runApp(const AdventsKalenderMasterApp());
}

class AdventsKalenderMasterApp extends StatelessWidget {
  const AdventsKalenderMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Die Flutter-Werkstatt · Adventskalender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFF10B981),
        ),
      ),
      home: const AdventsKalenderSchirm(),
    );
  }
}

class AdventsKalenderSchirm extends StatefulWidget {
  const AdventsKalenderSchirm({super.key});

  @override
  State<AdventsKalenderSchirm> createState() =>
      _AdventsKalenderSchirmState();
}

class _AdventsKalenderSchirmState
    extends State<AdventsKalenderSchirm> {
  int _aktiverTag = 24;

  final Map<int, String> _titel = {
    1: 'Der Mitternachtshimmel (LinearGradient)',
    2: 'Sanfte Schneehügel (CustomPainter & Bézier)',
    3: 'Der Tannenwald im Hintergrund (Modulo)',
    4: 'Funkelnde Sterne (math.Random mit Seed)',
    5: 'Die leuchtende Mondsichel (Path.combine)',
    6: 'Das erste Markthäuschen aus Holz',
    7: 'Der große Weihnachtsbaum auf dem Platz',
    8: 'Glänzende Christbaumkugeln mit Reflex',
    9: 'Pulsierende Lichterkette (AnimationController)',
    10: 'Gemütliche Marktstände mit Streifenmarkisen',
    11: 'Der goldene Stern auf der Baumspitze',
    12: 'Responsives Layout mit LayoutBuilder',
    13: 'Das Datenmodell für Schneeflocken',
    14: 'Das Schneegestöber erwacht (180 Partikel)',
    15: 'Winterwind & sanftes Taumeln',
    16: 'Interaktiver Wind per Wischgeste & Maus',
    17: 'Liegengebliebener Schnee auf den Dächern',
    18: 'Festliche Akustik & Sound-Schalter',
    19: 'Dampfender Kinderpunsch-Kessel',
    20: 'Prasselndes Kaminfeuer im Rathausfenster',
    21: 'Die historische Turmuhr zur vollen Stunde',
    22: 'Die Schneesturm-Turbotaste',
    23: 'Festliche Gold-Typografie',
    24: 'Das fertige Meisterwerk (Vollversion)',
  };

  Widget _baueAktuellenSchritt() {
    switch (_aktiverTag) {
      case 1:
        return const t01.Mitternachtshimmel();
      case 2:
        return CustomPaint(
          size: Size.infinite,
          painter: t02.SchneehuegelPainter(),
        );
      case 3:
        return CustomPaint(
          size: Size.infinite,
          painter: t03.TannenwaldPainter(),
        );
      case 4:
        return const t04.SternenBlick();
      case 5:
        return Center(
          child: CustomPaint(
            size: const Size(200, 200),
            painter: t05.MondPainter(),
          ),
        );
      case 6:
        return Center(
          child: CustomPaint(
            size: const Size(200, 150),
            painter: t06.HuettenPainter(),
          ),
        );
      case 7:
        return Center(
          child: CustomPaint(
            size: const Size(260, 260),
            painter: t07.ChristbaumPainter(),
          ),
        );
      case 8:
        return Center(
          child: CustomPaint(
            size: const Size(260, 260),
            painter: t08.KugelnPainter(),
          ),
        );
      case 9:
        return const t09.Tag09App();
      case 10:
        return Center(
          child: CustomPaint(
            size: const Size(200, 100),
            painter: t10.MarkisenPainter(),
          ),
        );
      case 11:
        return Center(
          child: CustomPaint(
            size: const Size(150, 150),
            painter: t11.SternPainter(),
          ),
        );
      case 12:
        return const t12.Tag12App();
      case 13:
        return const t13.Tag13App();
      case 14:
        return const t14.Tag14App();
      case 15:
        return const t15.Tag15App();
      case 16:
        return const t16.Tag16App();
      case 17:
        return Center(
          child: CustomPaint(
            size: const Size(200, 100),
            painter: t17.HaubenPainter(),
          ),
        );
      case 18:
        return const t18.Tag18App();
      case 19:
        return Center(
          child: CustomPaint(
            size: const Size(120, 120),
            painter: t19.KesselPainter(),
          ),
        );
      case 20:
        return const t20.Tag20App();
      case 21:
        return Center(
          child: CustomPaint(
            size: const Size(120, 120),
            painter: t21.TurmuhrPainter(),
          ),
        );
      case 22:
        return const t22.Tag22App();
      case 23:
        return const t23.Tag23App();
      case 24:
      default:
        return const t24.WeihnachtsMarktBlick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎄 Türchen $_aktiverTag von 24',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFBBF24),
              ),
            ),
            Text(
              _titel[_aktiverTag] ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: _aktiverTag > 1
                ? () => setState(() => _aktiverTag--)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: _aktiverTag < 24
                ? () => setState(() => _aktiverTag++)
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Aktuelle Ansicht
          Positioned.fill(
            child: _baueAktuellenSchritt(),
          ),

          // Untere Schritt-Auswahl
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Tag:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _aktiverTag.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 23,
                      activeColor: const Color(0xFFF59E0B),
                      inactiveColor: const Color(0xFF334155),
                      label: 'Türchen $_aktiverTag',
                      onChanged: (val) {
                        setState(() => _aktiverTag = val.round());
                      },
                    ),
                  ),
                  Text(
                    '$_aktiverTag / 24',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
