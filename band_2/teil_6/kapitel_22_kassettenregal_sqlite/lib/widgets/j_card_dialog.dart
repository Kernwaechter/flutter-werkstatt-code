import 'package:flutter/material.dart';

class KassetteInfo {
  final String titel;
  final String bandTyp;
  final Color farbe;
  final String dateiname;

  const KassetteInfo({
    required this.titel,
    required this.bandTyp,
    required this.farbe,
    required this.dateiname,
  });
}

class JCardDialog extends StatefulWidget {
  final String vorgeschlagenerTitel;

  const JCardDialog({
    super.key,
    this.vorgeschlagenerTitel = 'Mein 80er Mixtape',
  });

  @override
  State<JCardDialog> createState() => _JCardDialogState();
}

class _JCardDialogState extends State<JCardDialog> {
  late final TextEditingController _titelController;
  String _bandTyp = 'CrO2 II';
  Color _etikettFarbe = const Color(0xFFB45309);

  static const List<String> _typen = [
    'Fe I (Normal)',
    'CrO2 II (Chrome)',
    'Metal IV',
  ];

  static const List<Color> _farben = [
    Color(0xFFB45309), // Bernsteingold
    Color(0xFF1E293B), // Studio Anthrazit
    Color(0xFFBE185D), // Magenta 80s
    Color(0xFF047857), // Vintage Gruen
    Color(0xFF1D4ED8), // Royal Blau
  ];

  @override
  void initState() {
    super.initState();
    _titelController =
        TextEditingController(text: widget.vorgeschlagenerTitel);
  }

  @override
  void dispose() {
    _titelController.dispose();
    super.dispose();
  }

  // Bereinigt ungueltige Dateinamen-Zeichen fuer das Betriebssystem
  String _bereinigeDateinamen(String rohtext) {
    return rohtext
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E222A),
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Color(0xFFF59E0B)),
          SizedBox(width: 10),
          Text(
            'Kassette beschriften (J-Card)',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vorschau-Kassettenruecken / J-Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _etikettFarbe,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _titelController.text.isEmpty
                          ? 'Unbeschriftetes Tape'
                          : _titelController.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _bandTyp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titelController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mixtape-Titel',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF0F1115),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bandtyp:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF272B34),
              style: const TextStyle(color: Colors.white),
              initialValue: _typen[1], // CrO2
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF0F1115),
              ),
              items: _typen.map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _bandTyp = val);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Etiketten-Farbe:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _farben.map((c) {
                final selected = _etikettFarbe == c;
                return GestureDetector(
                  onTap: () => setState(() => _etikettFarbe = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final titel = _titelController.text.trim();
            final safeTitel =
                titel.isEmpty ? 'Unbenanntes_Tape' : titel;
            final dateiname =
                '${_bereinigeDateinamen(safeTitel)}.wav';

            Navigator.pop(
              context,
              KassetteInfo(
                titel: safeTitel,
                bandTyp: _bandTyp,
                farbe: _etikettFarbe,
                dateiname: dateiname,
              ),
            );
          },
          child: const Text('Kassette ins Regal stellen'),
        ),
      ],
    );
  }
}
