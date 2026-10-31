import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const VertretungsplanApp());
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
      home: const RohdatenSeite(),
    );
  }
}

class RohdatenSeite extends StatefulWidget {
  const RohdatenSeite({super.key});

  @override
  State<RohdatenSeite> createState() => _RohdatenSeiteState();
}

class _RohdatenSeiteState extends State<RohdatenSeite> {
  static const String _planUrl =
      'https://www.flutter-werkstatt.de/schule/vertretungsplan.json';

  late Future<String> _ladeVorgang;

  @override
  void initState() {
    super.initState();
    _ladeVorgang = _holeRohdaten();
  }

  Future<String> _holeRohdaten() async {
    try {
      final uri = Uri.parse(_planUrl);
      final antwort = await http
          .get(uri)
          .timeout(const Duration(seconds: 4));

      if (antwort.statusCode == 200) {
        return antwort.body;
      }
      throw Exception(
        'Server-Antwort: Statuscode ${antwort.statusCode}',
      );
    } catch (fehler) {
      // Falls du offline arbeitest, liefern wir den Übungsplan lokal:
      await Future.delayed(const Duration(milliseconds: 600));
      return _offlineBeispielJson;
    }
  }

  void _neuLaden() {
    setState(() {
      _ladeVorgang = _holeRohdaten();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'Vertretungsplan – Rohdaten',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Neu laden',
            onPressed: _neuLaden,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _ladeVorgang,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Lade Vertretungsplan vom Server...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 48,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Abruf fehlgeschlagen:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _neuLaden,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            );
          }

          final daten = snapshot.data ?? 'Keine Daten empfangen.';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daten,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF38BDF8),
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

const String _offlineBeispielJson = '''
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
      "stunde": "4.",
      "klasse": "9b",
      "fach": "Informatik",
      "lehrkraft": "Hr. Dähn",
      "raum": "IT-Labor 1",
      "status": "Vertretung",
      "hinweis": "Heute programmieren mit Flutter!"
    }
  ]
}
''';
