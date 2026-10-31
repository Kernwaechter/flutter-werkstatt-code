import 'dart:convert';
import 'package:flutter/material.dart';
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
  static const String _jsonUrl =
      'https://www.flutter-werkstatt.de/schule/vertretungsplan.json';

  final List<String> _klassen = ['Alle', '8a', '9b', '10a'];
  String _gewaehlteKlasse = 'Alle';
  String _suchText = '';

  late Future<List<Vertretung>> _ladeVorgang;

  @override
  void initState() {
    super.initState();
    _ladeVorgang = _ladeAusJson();
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
      await Future.delayed(const Duration(milliseconds: 400));
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
      _ladeVorgang = _ladeAusJson();
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
                      labelStyle: TextStyle(
                        fontWeight: istAktiv
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: istAktiv
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFF334155),
                      ),
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
                      borderSide: const BorderSide(
                        color: Color(0xFFCBD5E1),
                      ),
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

                if (gefiltert.isEmpty) {
                  return const Center(
                    child: Text(
                      'Keine Vertretungen für diese Auswahl.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gefiltert.length,
                  itemBuilder: (context, index) {
                    final v = gefiltert[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          child: Text(
                            v.stunde,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${v.klasse} · ${v.fach} (${v.status})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${v.lehrkraft} · Raum: ${v.raum}\n'
                          '${v.hinweis}',
                        ),
                        isThreeLine: true,
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

const String _offlineJson = '''
{
  "schule": "Gymnasium am Werkbankweg",
  "aktualisiert": "Montag, 07:35 Uhr",
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
    },
    {
      "stunde": "3.",
      "klasse": "10a",
      "fach": "Englisch",
      "lehrkraft": "Hr. Brandt (für Fr. Lindner)",
      "raum": "R211",
      "status": "Vertretung",
      "hinweis": "Buch S. 44 mitbringen"
    },
    {
      "stunde": "3.",
      "klasse": "8a",
      "fach": "Biologie",
      "lehrkraft": "Fr. Sommer",
      "raum": "Bio-1",
      "status": "Raumwechsel",
      "hinweis": "Mikroskopieren"
    },
    {
      "stunde": "4.",
      "klasse": "9b",
      "fach": "Informatik",
      "lehrkraft": "Hr. Dähn",
      "raum": "IT-Labor 1",
      "status": "Vertretung",
      "hinweis": "Wir programmieren heute mit Flutter!"
    },
    {
      "stunde": "5.",
      "klasse": "10a",
      "fach": "Geschichte",
      "lehrkraft": "Hr. Scholz",
      "raum": null,
      "status": "Entfall",
      "hinweis": "Selbststudium in der Bibliothek"
    },
    {
      "stunde": "6.",
      "klasse": "8a",
      "fach": "Sport",
      "lehrkraft": "Fr. Krüger",
      "raum": "Sporthalle Süd",
      "status": "Verlegung",
      "hinweis": "Wegen Hallensperrung in Halle Süd"
    },
    {
      "stunde": "6.",
      "klasse": "9b",
      "fach": "Kunst",
      "lehrkraft": "Fr. Albrecht",
      "raum": null,
      "status": "Entfall",
      "hinweis": "Unterrichtsschluss nach der 5. Stunde"
    }
  ]
}
''';
