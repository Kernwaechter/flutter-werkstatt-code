import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sammlungsstueck.dart';

class TresorScreen extends StatefulWidget {
  const TresorScreen({super.key});

  @override
  State<TresorScreen> createState() => _TresorScreenState();
}

class _TresorScreenState extends State<TresorScreen> {
  final _suchController = TextEditingController();
  String _gewaehlteKategorie = 'Alle';
  String _sortierung = 'titel_asc';

  List<Sammlungsstueck> _stuecke = [];
  double _gesamtwert = 0.0;
  bool _laedt = true;

  final List<String> _kategorien = [
    'Alle',
    'Computer',
    'Konsole',
    'Audio',
    'Zubehör',
  ];

  @override
  void initState() {
    super.initState();
    _ladeDaten();
  }

  @override
  void dispose() {
    _suchController.dispose();
    super.dispose();
  }

  Future<void> _ladeDaten() async {
    setState(() => _laedt = true);
    final daten = await DbHelper.suchen(
      suchtext: _suchController.text,
      kategorie: _gewaehlteKategorie,
      sortierung: _sortierung,
    );
    final summe = await DbHelper.berechneGesamtwert();
    setState(() {
      _stuecke = daten;
      _gesamtwert = summe;
      _laedt = false;
    });
  }

  void _zeigeEditorDialog({Sammlungsstueck? vorhandenes}) {
    final titelController =
        TextEditingController(text: vorhandenes?.titel ?? '');
    final wertController = TextEditingController(
      text: vorhandenes != null
          ? vorhandenes.schaetzwert.toStringAsFixed(2)
          : '50.00',
    );
    final notizController =
        TextEditingController(text: vorhandenes?.notiz ?? '');
    String kategorie = vorhandenes?.kategorie ?? 'Computer';
    String zustand = vorhandenes?.zustand ?? 'Gut';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(vorhandenes == null
                  ? 'Neues Sammlungsstück'
                  : 'Stück bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titelController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung / Modell',
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
                        DropdownMenuItem(
                            value: 'Zubehör', child: Text('Zubehör')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => kategorie = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: zustand,
                      decoration: const InputDecoration(
                        labelText: 'Zustand',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Neu / OVP', child: Text('Neu / OVP')),
                        DropdownMenuItem(
                            value: 'Sammlerzustand',
                            child: Text('Sammlerzustand')),
                        DropdownMenuItem(
                            value: 'Sehr gut', child: Text('Sehr gut')),
                        DropdownMenuItem(value: 'Gut', child: Text('Gut')),
                        DropdownMenuItem(
                            value: 'Bastlerobjekt',
                            child: Text('Bastlerobjekt')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => zustand = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notizController,
                      decoration: const InputDecoration(
                        labelText: 'Besonderheiten / Notiz',
                        border: OutlineInputBorder(),
                      ),
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

                    if (vorhandenes == null) {
                      await DbHelper.einfuegen(Sammlungsstueck(
                        titel: titel,
                        kategorie: kategorie,
                        schaetzwert: wert,
                        zustand: zustand,
                        notiz: notizController.text.trim(),
                      ));
                    } else {
                      await DbHelper.aktualisieren(vorhandenes.copyWith(
                        titel: titel,
                        kategorie: kategorie,
                        schaetzwert: wert,
                        zustand: zustand,
                        notiz: notizController.text.trim(),
                      ));
                    }

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
        title: const Text('Flohmarkt- & Sammlungs-Tresor'),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _suchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Stück suchen...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _suchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white70),
                            onPressed: () {
                              _suchController.clear();
                              _ladeDaten();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF334155),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (text) => _ladeDaten(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF334155),
                        style: const TextStyle(color: Colors.white),
                        initialValue: _gewaehlteKategorie,
                        decoration: InputDecoration(
                          labelText: 'Kategorie',
                          labelStyle:
                              const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF334155),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _kategorien.map((k) {
                          return DropdownMenuItem(
                            value: k,
                            child: Text(k),
                          );
                        }).toList(),
                        onChanged: (k) {
                          if (k != null) {
                            setState(() => _gewaehlteKategorie = k);
                            _ladeDaten();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF334155),
                        style: const TextStyle(color: Colors.white),
                        initialValue: _sortierung,
                        decoration: InputDecoration(
                          labelText: 'Sortierung',
                          labelStyle:
                              const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF334155),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'titel_asc',
                            child: Text('Titel (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: 'wert_desc',
                            child: Text('Wert (hoch)'),
                          ),
                          DropdownMenuItem(
                            value: 'wert_asc',
                            child: Text('Wert (niedrig)'),
                          ),
                        ],
                        onChanged: (s) {
                          if (s != null) {
                            setState(() => _sortierung = s);
                            _ladeDaten();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE2E8F0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_stuecke.length} Treffer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Gesamtwert: ${_gesamtwert.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
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
                          'Keine Sammlungsstücke gefunden.',
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
                                '${item.kategorie} · Zustand: ${item.zustand}'
                                '${item.notiz.isNotEmpty ? "\n" + item.notiz : ""}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${item.schaetzwert.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                      fontSize: 15,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 20, color: Colors.grey),
                                    onPressed: () => _zeigeEditorDialog(
                                      vorhandenes: item,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: Colors.redAccent),
                                    onPressed: () async {
                                      if (item.id != null) {
                                        await DbHelper.loeschen(item.id!);
                                        _ladeDaten();
                                      }
                                    },
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
        onPressed: () => _zeigeEditorDialog(),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schätzchen erfassen'),
      ),
    );
  }
}
