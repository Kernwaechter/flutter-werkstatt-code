import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sammlungsstueck.dart';

class TresorScreen extends StatefulWidget {
  const TresorScreen({super.key});

  @override
  State<TresorScreen> createState() => _TresorScreenState();
}

class _TresorScreenState extends State<TresorScreen> {
  List<Sammlungsstueck> _stuecke = [];
  bool _laedt = true;

  @override
  void initState() {
    super.initState();
    _ladeDaten();
  }

  Future<void> _ladeDaten() async {
    setState(() => _laedt = true);
    final daten = await DbHelper.ladeAlle();
    setState(() {
      _stuecke = daten;
      _laedt = false;
    });
  }

  Future<void> _exportiereBackup() async {
    try {
      final pfad = await DbHelper.exportiereBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup erfolgreich gespeichert in:\n$pfad'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Backup: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _importiereBackup() async {
    try {
      final anzahl = await DbHelper.importiereBackup();
      await _ladeDaten();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$anzahl Datensätze erfolgreich wiederhergestellt!'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Wiederherstellen: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _zeigeNeuesDialog() {
    final titelController = TextEditingController();
    final wertController = TextEditingController(text: '120.00');
    final kaufpreisController = TextEditingController(text: '20.00');
    String kategorie = 'Computer';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Neues Stück mit Kaufpreis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titelController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kaufpreisController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kaufpreis (€) [Neu in V2]',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: wertController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Aktueller Schätzwert (€)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: kategorie,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Computer', child: Text('Computer')),
                        DropdownMenuItem(
                            value: 'Konsole', child: Text('Konsole')),
                        DropdownMenuItem(
                            value: 'Audio', child: Text('Audio')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => kategorie = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () async {
                    final titel = titelController.text.trim();
                    if (titel.isEmpty) return;
                    final wert = double.tryParse(
                          wertController.text.replaceAll(',', '.'),
                        ) ??
                        0.0;
                    final kauf = double.tryParse(
                          kaufpreisController.text.replaceAll(',', '.'),
                        ) ??
                        0.0;

                    await DbHelper.einfuegen(Sammlungsstueck(
                      titel: titel,
                      kategorie: kategorie,
                      schaetzwert: wert,
                      kaufpreis: kauf,
                    ));

                    if (mounted) {
                      Navigator.pop(ctx);
                      _ladeDaten();
                    }
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double gesamtKaufpreis = 0;
    double gesamtSchaetzwert = 0;
    for (final s in _stuecke) {
      gesamtKaufpreis += s.kaufpreis;
      gesamtSchaetzwert += s.schaetzwert;
    }
    final gewinn = gesamtSchaetzwert - gesamtKaufpreis;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text('Tresor: Migration V2 & Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'JSON-Backup exportieren',
            onPressed: _exportiereBackup,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'JSON-Backup importieren',
            onPressed: _importiereBackup,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatistikBox(
                  titel: 'Investition',
                  wert: '${gesamtKaufpreis.toStringAsFixed(2)} €',
                  farbe: const Color(0xFF94A3B8),
                ),
                _StatistikBox(
                  titel: 'Schätzwert',
                  wert: '${gesamtSchaetzwert.toStringAsFixed(2)} €',
                  farbe: const Color(0xFF38BDF8),
                ),
                _StatistikBox(
                  titel: 'Buchgewinn',
                  wert: '+${gewinn.toStringAsFixed(2)} €',
                  farbe: const Color(0xFF4ADE80),
                ),
              ],
            ),
          ),
          Expanded(
            child: _laedt
                ? const Center(child: CircularProgressIndicator())
                : _stuecke.isEmpty
                    ? const Center(
                        child: Text(
                          'Noch keine Stücke vorhanden.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stuecke.length,
                        itemBuilder: (context, index) {
                          final item = _stuecke[index];
                          final profit = item.schaetzwert - item.kaufpreis;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                child: Text(item.kategorie.isNotEmpty
                                    ? item.kategorie[0]
                                    : '?'),
                              ),
                              title: Text(
                                item.titel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Kauf: ${item.kaufpreis.toStringAsFixed(2)} €  ·  '
                                'Wert: ${item.schaetzwert.toStringAsFixed(2)} €',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${profit.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Text(
                                    'Gewinn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _zeigeNeuesDialog,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Stück erfassen'),
      ),
    );
  }
}

class _StatistikBox extends StatelessWidget {
  final String titel;
  final String wert;
  final Color farbe;

  const _StatistikBox({
    required this.titel,
    required this.wert,
    required this.farbe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          wert,
          style: TextStyle(
            color: farbe,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titel,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
