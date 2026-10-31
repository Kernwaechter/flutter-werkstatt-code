import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SchulhelferApp());
}

class Hausaufgabe {
  final String fach;
  final String titel;
  final DateTime faelligAm;
  bool istErledigt;

  Hausaufgabe({
    required this.fach,
    required this.titel,
    required this.faelligAm,
    this.istErledigt = false,
  });
}

class SchulhelferApp extends StatelessWidget {
  const SchulhelferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Schulhelfer 1.0',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const AufgabenSeite(),
    );
  }
}

class AufgabenSeite extends StatefulWidget {
  const AufgabenSeite({super.key});

  @override
  State<AufgabenSeite> createState() => _AufgabenSeiteState();
}

class _AufgabenSeiteState extends State<AufgabenSeite> {
  final List<String> _faecher = [
    'Mathe',
    'Englisch',
    'Deutsch',
    'Physik',
    'Informatik',
    'Geschichte',
  ];

  late final List<Hausaufgabe> _aufgaben = [
    Hausaufgabe(
      fach: 'Mathe',
      titel: 'Buch S. 42, Aufgabe 3a bis 3d',
      faelligAm: DateTime.now().add(const Duration(days: 1)),
    ),
    Hausaufgabe(
      fach: 'Englisch',
      titel: 'Unit 3: Vokabeln wiederholen',
      faelligAm: DateTime.now().add(const Duration(days: 3)),
    ),
    Hausaufgabe(
      fach: 'Informatik',
      titel: 'Fokus-Timer in Flutter testen',
      faelligAm: DateTime.now(),
    ),
  ];

  Timer? _fokusTimer;
  int _restSekunden = 25 * 60;
  bool _timerLaeuft = false;

  @override
  void dispose() {
    _fokusTimer?.cancel();
    super.dispose();
  }

  void _startStopTimer() {
    if (_timerLaeuft) {
      _fokusTimer?.cancel();
      setState(() => _timerLaeuft = false);
    } else {
      setState(() => _timerLaeuft = true);
      _fokusTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (_restSekunden > 0) {
            setState(() => _restSekunden--);
          } else {
            timer.cancel();
            setState(() => _timerLaeuft = false);
          }
        },
      );
    }
  }

  void _resetTimer() {
    _fokusTimer?.cancel();
    setState(() {
      _timerLaeuft = false;
      _restSekunden = 25 * 60;
    });
  }

  String get _formatierteZeit {
    final min = (_restSekunden ~/ 60).toString().padLeft(2, '0');
    final sek = (_restSekunden % 60).toString().padLeft(2, '0');
    return '$min:$sek';
  }

  String _fristText(DateTime datum) {
    final heute = DateUtils.dateOnly(DateTime.now());
    final ziel = DateUtils.dateOnly(datum);
    final tage = ziel.difference(heute).inDays;

    final tagStr =
        '${ziel.day.toString().padLeft(2, '0')}.'
        '${ziel.month.toString().padLeft(2, '0')}.';

    if (tage < 0) return 'Überfällig ($tagStr)';
    if (tage == 0) return 'Heute ($tagStr)';
    if (tage == 1) return 'Morgen ($tagStr)';
    return 'In $tage Tagen ($tagStr)';
  }

  int get _offeneAnzahl =>
      _aufgaben.where((a) => !a.istErledigt).length;

  Color _fachFarbe(String fach) {
    switch (fach) {
      case 'Mathe':
        return const Color(0xFF2563EB);
      case 'Englisch':
        return const Color(0xFF0D9488);
      case 'Informatik':
        return const Color(0xFF7C3AED);
      case 'Physik':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  void _oeffneEingabeBlatt() {
    final titelController = TextEditingController();
    String gewaehltesFach = _faecher.first;
    DateTime gewaehltesDatum =
        DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Neue Hausaufgabe eintragen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: gewaehltesFach,
                    decoration: const InputDecoration(
                      labelText: 'Schulfach',
                      border: OutlineInputBorder(),
                    ),
                    items: _faecher.map((fach) {
                      return DropdownMenuItem(
                        value: fach,
                        child: Text(fach),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setSheetState(() {
                        gewaehltesFach = val ?? 'Mathe';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titelController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Was ist zu tun?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final gepickt = await showDatePicker(
                        context: context,
                        initialDate: gewaehltesDatum,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (gepickt != null) {
                        setSheetState(() {
                          gewaehltesDatum = gepickt;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      'Fällig: ${_fristText(gewaehltesDatum)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final eingabe = titelController.text.trim();
                      if (eingabe.isEmpty) return;

                      setState(() {
                        _aufgaben.insert(
                          0,
                          Hausaufgabe(
                            fach: gewaehltesFach,
                            titel: eingabe,
                            faelligAm: gewaehltesDatum,
                          ),
                        );
                      });
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text(
                      'Aufgabe speichern',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'Schulhelfer 1.0',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Noch $_offeneAnzahl offen',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FOKUS-STOPPUHR',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatierteZeit,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _timerLaeuft
                            ? const Color(0xFFD97706)
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _startStopTimer,
                      icon: Icon(
                        _timerLaeuft ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(_timerLaeuft ? 'Pause' : 'Start'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _resetTimer,
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _aufgaben.length,
              itemBuilder: (context, index) {
                final aufgabe = _aufgaben[index];
                final farbe = _fachFarbe(aufgabe.fach);

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: aufgabe.istErledigt ? 0.55 : 1.0,
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Checkbox(
                        value: aufgabe.istErledigt,
                        activeColor: farbe,
                        onChanged: (neuerWert) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            aufgabe.istErledigt = neuerWert ?? false;
                          });
                        },
                      ),
                      title: Text(
                        aufgabe.titel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: aufgabe.istErledigt
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: aufgabe.istErledigt
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: farbe.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                aufgabe.fach,
                                style: TextStyle(
                                  color: farbe,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _fristText(aufgabe.faelligAm),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          setState(() {
                            _aufgaben.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: _oeffneEingabeBlatt,
        icon: const Icon(Icons.add),
        label: const Text('Neue Aufgabe'),
      ),
    );
  }
}
