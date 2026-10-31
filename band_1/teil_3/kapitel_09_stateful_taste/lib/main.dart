import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: SoundTaste(),
        ),
      ),
    ),
  );
}

class SoundTaste extends StatefulWidget {
  const SoundTaste({super.key});

  @override
  State<SoundTaste> createState() => _SoundTasteState();
}

class _SoundTasteState extends State<SoundTaste> {
  int beatZaehler = 0;
  bool istAktiv = false;

  void tasteGedrueckt() {
    setState(() {
      beatZaehler = beatZaehler + 1;
      istAktiv = !istAktiv;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tasteGedrueckt,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: istAktiv
              ? const Color(0xFF0284C7)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: istAktiv
                ? const Color(0xFF38BDF8)
                : const Color(0xFF334155),
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              istAktiv ? Icons.volume_up : Icons.music_note,
              size: 48,
              color: const Color(0xFFF8FAFC),
            ),
            const SizedBox(height: 12),
            const Text(
              'KICK DRUM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF8FAFC),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Beats: $beatZaehler',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
