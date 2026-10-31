import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sammlungsstueck.dart';
import '../models/standort.dart';

class TresorScreen extends StatefulWidget {
  const TresorScreen({super.key});

  @override
  State<TresorScreen> createState() => _TresorScreenState();
}

class _TresorScreenState extends State<TresorScreen> {
  List<Sammlungsstueck> _stuecke = [];
  List<Standort> _standorte = [];
  bool _laedt = true;

  @override
  void initState() {
    super.initState();
    _ladeDaten();
  }

  Future<void> _ladeDaten() async {
    setState(() => _laedt = true);
    final sList = await DbHelper.ladeStandorte();
    final mList = await DbHelper.ladeAlleMitStandort();
    setState(() {
      _standorte = sList;
      _stuecke = mList;
      _laedt = false;
    });
  }

  Future<void> _loescheMitRueckgaengig(
    Sammlungsstueck item,
    int index,
  ) async {
    if (item.id == null) return;
    final geloeschteId = item.id!;

    // 1. Zunaechst lokal aus der Liste nehmen fuer fluessige Animation
    setState(() {
      _stuecke.removeAt(index);
    });

    // 2. In SQLite loeschen
    await DbHelper.loeschen(geloeschteId);

    if (!mounted) return;

    // 3. SnackBar mit Rueckgaengig-Aktion anbieten
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('„${item.titel}“ wurde gelöscht.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RÜCKGÄNGIG',
          textColor: const Color(0xFF38BDF8),
          onPressed: () async {
            await DbHelper.wiederherstellen(item);
            _ladeDaten();
          },
        ),
      ),
    );
  }

  void _zeigeNeuesDialog() {
    final titelController = TextEditingController();
    final wertController = TextEditingController(text: '75.00');
    int? gewaehlterStandortId =
        _standorte.isNotEmpty ? _standorte.first.id : null;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Neues Sammlungsstück'),
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
                      controller: wertController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Schätzwert (€)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: gewaehlterStandortId,
                      decoration: const InputDecoration(
                        labelText: 'Lagerort (Standort)',
                        border: OutlineInputBorder(),
                      ),
                      items: _standorte.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setDialogState(() => gewaehlterStandortId = id);
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

                    await DbHelper.einfuegen(Sammlungsstueck(
                      titel: titel,
                      kategorie: 'Retro',
                      schaetzwert: wert,
                      standortId: gewaehlterStandortId,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text('Tresor: Fremdschlüssel & Undo'),
      ),
      body: _laedt
          ? const Center(child: CircularProgressIndicator())
          : _stuecke.isEmpty
              ? const Center(
                  child: Text(
                    'Tresor ist leer. Wische zum Löschen!',
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
                    return Dismissible(
                      key: ValueKey(item.id ?? index),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'LÖSCHEN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.delete, color: Colors.white),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        _loescheMitRueckgaengig(item, index);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            child: Icon(Icons.inventory_2, size: 20),
                          ),
                          title: Text(
                            item.titel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Ort: ${item.standortName ?? "Nicht zugeordnet"}',
                            style: const TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Text(
                            '${item.schaetzwert.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _zeigeNeuesDialog,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Neues Stück'),
      ),
    );
  }
}
