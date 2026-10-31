import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SoundboardScreen(),
    ),
  );
}

class SoundboardScreen extends StatefulWidget {
  const SoundboardScreen({super.key});

  @override
  State<SoundboardScreen> createState() => _SoundboardScreenState();
}

class _SoundboardScreenState extends State<SoundboardScreen> {
  final AudioPlayer player = AudioPlayer();

  final List<String> padNamen = [
    'Kick',
    'Snare',
    'Hi-Hat',
    'Clap',
    'Bass',
    'Synth',
    'Laser',
    'Horn',
    'Drop',
  ];

  String aktivesPad = 'Bereit';
  int gesamtBeats = 0;
  double lautstaerke = 0.8;
  bool mixModus = true;

  Future<void> padAbspielen(String name) async {
    final String dateiName = name
        .toLowerCase()
        .replaceAll('-', '');

    setState(() {
      aktivesPad = name;
      gesamtBeats = gesamtBeats + 1;
    });

    if (mixModus) {
      final AudioPlayer mixPlayer = AudioPlayer();
      await mixPlayer.setVolume(lautstaerke);
      await mixPlayer.play(
        AssetSource('sounds/$dateiName.wav'),
        mode: PlayerMode.lowLatency,
      );
    } else {
      await player.stop();
      await player.setVolume(lautstaerke);
      await player.play(AssetSource('sounds/$dateiName.wav'));
    }
  }

  Future<void> allesStoppen() async {
    await player.stop();
    setState(() {
      aktivesPad = 'Bereit';
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int prozent = (lautstaerke * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Studio-Deck',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          mixModus = !mixModus;
                        });
                      },
                      child: Text(
                        mixModus ? 'Modus: MIX' : 'Modus: SOLO',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 330,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      for (final String name in padNamen)
                        SoundPad(
                          titel: name,
                          istAktiv: aktivesPad == name,
                          onTap: () => padAbspielen(name),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Lautstärke: $prozent %',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: lautstaerke,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFFF59E0B),
                          onChanged: (neuerWert) {
                            setState(() {
                              lautstaerke = neuerWert;
                            });
                            player.setVolume(neuerWert);
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: allesStoppen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: const Color(0xFFFFFFFF),
                        ),
                        child: const Text('Stopp'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SoundPad extends StatelessWidget {
  final String titel;
  final bool istAktiv;
  final VoidCallback onTap;

  const SoundPad({
    super.key,
    required this.titel,
    required this.istAktiv,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: istAktiv
              ? const Color(0xFFD97706)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: istAktiv
                ? const Color(0xFFF59E0B)
                : const Color(0xFF334155),
            width: 2,
          ),
          boxShadow: istAktiv
              ? [
                  const BoxShadow(
                    color: Color(0x66F59E0B),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              istAktiv ? 'SPIELT...' : 'Bereit',
              style: TextStyle(
                fontSize: 11,
                color: istAktiv
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
