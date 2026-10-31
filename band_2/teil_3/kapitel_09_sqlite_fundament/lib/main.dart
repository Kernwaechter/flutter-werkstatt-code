import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'models/sammlungsstueck.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SqliteFundamentApp());
}

class SqliteFundamentApp extends StatelessWidget {
  const SqliteFundamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SQLite Fundament',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const FundamentScreen(),
    );
  }
}

class FundamentScreen extends StatefulWidget {
  const FundamentScreen({super.key});

  @override
  State<FundamentScreen> createState() => _FundamentScreenState();
}

class _FundamentScreenState extends State<FundamentScreen> {
  List<Sammlungsstueck> _stuecke = [];
  bool _laedt = true;

  @override
  void initState() {
    super.initState();
    _ladeDaten();
  }

  Future<void> _ladeDaten() async {
    setState(() => _laedt = true);
    final daten = await DbHelper.alleLesen();
    setState(() {
      _stuecke = daten;
      _laedt = false;
    });
  }

  Future<void> _beispielEinfuegen() async {
    final neu = Sammlungsstueck(
      titel: 'Commodore 64 (#${_stuecke.length + 1})',
      kategorie: 'Computer',
      schaetzwert: 150.0 + (_stuecke.length * 20),
    );
    await DbHelper.einfuegen(neu);
    await _ladeDaten();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text('Kapitel 9: SQLite Fundament'),
      ),
      body: _laedt
          ? const Center(child: CircularProgressIndicator())
          : _stuecke.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storage,
                          size: 64, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 16),
                      const Text(
                        'Noch keine Datensätze in der Datenbank.',
                        style: TextStyle(
                            fontSize: 16, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _beispielEinfuegen,
                        icon: const Icon(Icons.add),
                        label: const Text('Ersten Eintrag in SQLite speichern'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stuecke.length,
                  itemBuilder: (context, index) {
                    final item = _stuecke[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          child: Text('#${item.id ?? index + 1}'),
                        ),
                        title: Text(item.titel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('Kategorie: ${item.kategorie}'),
                        trailing: Text(
                          '${item.schaetzwert.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _beispielEinfuegen,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
