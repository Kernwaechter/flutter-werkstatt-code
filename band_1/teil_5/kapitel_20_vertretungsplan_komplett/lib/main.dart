import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

void main() {
  runApp(const VertretungsplanApp());
}

class Vertretung {
  final String stunde;
  final String klasse;
  final String fach;
  final String lehrkraft;
  final String raum;
  final String status;
  final String hinweis;

  const Vertretung({
    required this.stunde,
    required this.klasse,
    required this.fach,
    required this.lehrkraft,
    required this.raum,
    required this.status,
    required this.hinweis,
  });

  factory Vertretung.fromJson(Map<String, dynamic> json) {
    return Vertretung(
      stunde: json['stunde'] as String? ?? '?',
      klasse: json['klasse'] as String? ?? 'Alle',
      fach: json['fach'] as String? ?? 'Unbekannt',
      lehrkraft: json['lehrkraft'] as String? ?? '-',
      raum: json['raum'] as String? ?? 'Kein Raum',
      status: json['status'] as String? ?? 'Hinweis',
      hinweis: json['hinweis'] as String? ?? '',
    );
  }
}

class StatusStil {
  final Color hintergrund;
  final Color vordergrund;
  final IconData icon;

  const StatusStil({
    required this.hintergrund,
    required this.vordergrund,
    required this.icon,
  });
}

StatusStil stilFuerStatus(String status) {
  return switch (status.toLowerCase()) {
    'entfall' => const StatusStil(
        hintergrund: Color(0xFFFEE2E2),
        vordergrund: Color(0xFF991B1B),
        icon: Icons.cancel_outlined,
      ),
    'raumwechsel' || 'verlegung' => const StatusStil(
        hintergrund: Color(0xFFFEF3C7),
        vordergrund: Color(0xFF92400E),
        icon: Icons.meeting_room_outlined,
      ),
    'vertretung' => const StatusStil(
        hintergrund: Color(0xFFDBEAFE),
        vordergrund: Color(0xFF1E40AF),
        icon: Icons.person_outline,
      ),
    _ => const StatusStil(
        hintergrund: Color(0xFFE2E8F0),
        vordergrund: Color(0xFF334155),
        icon: Icons.info_outline,
      ),
  };
}

class VertretungsplanApp extends StatelessWidget {
  const VertretungsplanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vertretungsplan-Veredeler',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const PlanSeite(),
    );
  }
}

class PlanSeite extends StatefulWidget {
  const PlanSeite({super.key});

  @override
  State<PlanSeite> createState() => _PlanSeiteState();
}

class _PlanSeiteState extends State<PlanSeite> {
  static const String _htmlUrl =
      'https://www.flutter-werkstatt.de/schule/vertretungsplan.html';
  static const String _jsonUrl =
      'https://www.flutter-werkstatt.de/schule/vertretungsplan.json';

  final List<String> _klassen = ['Alle', '8a', '9b', '10a'];
  String _gewaehlteKlasse = 'Alle';
  String _suchText = '';
  bool _nutzeHtmlScraper = true;

  late Future<List<Vertretung>> _ladeVorgang;

  @override
  void initState() {
    super.initState();
    _ladeVorgang = _ladeDaten();
  }

  Future<List<Vertretung>> _ladeDaten() {
    if (_nutzeHtmlScraper) {
      return _scrapeVonHtmlWebseite();
    }
    return _ladeAusJson();
  }

  Future<List<Vertretung>> _scrapeVonHtmlWebseite() async {
    String htmlText;
    try {
      final antwort = await http
          .get(Uri.parse(_htmlUrl))
          .timeout(const Duration(seconds: 4));
      if (antwort.statusCode == 200) {
        htmlText = utf8.decode(antwort.bodyBytes);
      } else {
        htmlText = _offlineHtml;
      }
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 350));
      htmlText = _offlineHtml;
    }

    final dokument = html_parser.parse(htmlText);
    final zeilen =
        dokument.querySelectorAll('#vertretungsplan tr');

    final List<Vertretung> ergebnis = [];

    for (final zeile in zeilen) {
      final zellen = zeile.querySelectorAll('td');
      if (zellen.length < 7) continue;

      final raumText = zellen[4].text.trim();
      ergebnis.add(
        Vertretung(
          stunde: zellen[0].text.trim(),
          klasse: zellen[1].text.trim(),
          fach: zellen[2].text.trim(),
          lehrkraft: zellen[3].text.trim(),
          raum: (raumText.isEmpty || raumText == '---')
              ? 'Kein Raum'
              : raumText,
          status: zellen[5].text.trim(),
          hinweis: zellen[6].text.trim(),
        ),
      );
    }

    return ergebnis;
  }

  Future<List<Vertretung>> _ladeAusJson() async {
    String rohText;
    try {
      final antwort = await http
          .get(Uri.parse(_jsonUrl))
          .timeout(const Duration(seconds: 4));
      if (antwort.statusCode == 200) {
        rohText = utf8.decode(antwort.bodyBytes);
      } else {
        rohText = _offlineJson;
      }
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 350));
      rohText = _offlineJson;
    }

    final Map<String, dynamic> daten = jsonDecode(rohText);
    final List<dynamic> rohListe =
        daten['eintraege'] as List<dynamic>? ?? [];

    return rohListe
        .map((e) => Vertretung.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _aktualisieren() {
    setState(() {
      _ladeVorgang = _ladeDaten();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'Vertretungsplan-Veredeler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _nutzeHtmlScraper = !_nutzeHtmlScraper;
                _ladeVorgang = _ladeDaten();
              });
            },
            icon: Icon(
              _nutzeHtmlScraper ? Icons.code : Icons.data_object,
              color: const Color(0xFF38BDF8),
              size: 18,
            ),
            label: Text(
              _nutzeHtmlScraper ? 'HTML' : 'JSON',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aktualisieren',
            onPressed: _aktualisieren,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: _klassen.map((klasse) {
                    final istAktiv = _gewaehlteKlasse == klasse;
                    return FilterChip(
                      label: Text(
                        klasse == 'Alle'
                            ? 'Alle Klassen'
                            : 'Klasse $klasse',
                      ),
                      selected: istAktiv,
                      selectedColor: const Color(0xFFDBEAFE),
                      checkmarkColor: const Color(0xFF1D4ED8),
                      onSelected: (_) {
                        setState(() {
                          _gewaehlteKlasse = klasse;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Nach Fach oder Lehrkraft suchen...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (wert) {
                    setState(() {
                      _suchText = wert.trim().toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Vertretung>>(
              future: _ladeVorgang,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Fehler: ${snapshot.error}'),
                  );
                }

                final alle = snapshot.data ?? [];
                final gefiltert = alle.where((eintrag) {
                  final passtKlasse = _gewaehlteKlasse == 'Alle' ||
                      eintrag.klasse == _gewaehlteKlasse;
                  final passtSuche = _suchText.isEmpty ||
                      eintrag.fach
                          .toLowerCase()
                          .contains(_suchText) ||
                      eintrag.lehrkraft
                          .toLowerCase()
                          .contains(_suchText);
                  return passtKlasse && passtSuche;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gefiltert.length,
                  itemBuilder: (context, index) {
                    final v = gefiltert[index];
                    final stil = stilFuerStatus(v.status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: stil.hintergrund,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                v.stunde,
                                style: TextStyle(
                                  color: stil.vordergrund,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${v.klasse} · ${v.fach}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: stil.hintergrund,
                                          borderRadius:
                                              BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Icon(
                                              stil.icon,
                                              size: 14,
                                              color: stil.vordergrund,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              v.status,
                                              style: TextStyle(
                                                color:
                                                    stil.vordergrund,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${v.lehrkraft} · '
                                    'Raum: ${v.raum}',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (v.hinweis.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      v.hinweis,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const String _offlineHtml = '''
<table id="vertretungsplan">
  <thead>
    <tr>
      <th>Stunde</th><th>Klasse</th><th>Fach</th>
      <th>Lehrkraft</th><th>Raum</th><th>Status</th><th>Hinweis</th>
    </tr>
  </thead>
  <tbody>
    <tr class="vertretung-zeile">
      <td>1.</td><td>9b</td><td>Mathematik</td>
      <td>Fr. Weber</td><td>---</td><td>Entfall</td>
      <td>Aufgaben im Lernportal beachten</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>2.</td><td>9b</td><td>Physik</td>
      <td>Hr. Kästner</td><td>Ph-2 (statt R104)</td>
      <td>Raumwechsel</td>
      <td>Experimentierkasten mitbringen</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>3.</td><td>10a</td><td>Englisch</td>
      <td>Hr. Brandt (für Fr. Lindner)</td><td>R211</td>
      <td>Vertretung</td>
      <td>Buch S. 44 mitbringen</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>3.</td><td>8a</td><td>Biologie</td>
      <td>Fr. Sommer</td><td>Bio-1</td><td>Raumwechsel</td>
      <td>Mikroskopieren</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>4.</td><td>9b</td><td>Informatik</td>
      <td>Hr. Dähn</td><td>IT-Labor 1</td><td>Vertretung</td>
      <td>Wir programmieren heute mit Flutter!</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>5.</td><td>10a</td><td>Geschichte</td>
      <td>Hr. Scholz</td><td>---</td><td>Entfall</td>
      <td>Selbststudium in der Bibliothek</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>6.</td><td>8a</td><td>Sport</td>
      <td>Fr. Krüger</td><td>Sporthalle Süd</td><td>Verlegung</td>
      <td>Wegen Hallensperrung in Halle Süd</td>
    </tr>
    <tr class="vertretung-zeile">
      <td>6.</td><td>9b</td><td>Kunst</td>
      <td>Fr. Albrecht</td><td>---</td><td>Entfall</td>
      <td>Unterrichtsschluss nach der 5. Stunde</td>
    </tr>
  </tbody>
</table>
''';

const String _offlineJson = '''
{
  "schule": "Gymnasium am Werkbankweg",
  "eintraege": [
    {
      "stunde": "1.",
      "klasse": "9b",
      "fach": "Mathematik",
      "lehrkraft": "Fr. Weber",
      "raum": null,
      "status": "Entfall",
      "hinweis": "Aufgaben im Lernportal beachten"
    },
    {
      "stunde": "2.",
      "klasse": "9b",
      "fach": "Physik",
      "lehrkraft": "Hr. Kästner",
      "raum": "Ph-2 (statt R104)",
      "status": "Raumwechsel",
      "hinweis": "Experimentierkasten mitbringen"
    }
  ]
}
''';
