import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Robuster Parser mit strengen Integritäts- und Bounds-Checks
class PaketParser {
  static const int magicExpected = 0x54555242; // 'TURB'
  static const int minPacketSize = 16;
  static const int maxPayloadSize = 10 * 1024 * 1024; // 10 MB Limit

  static (bool, String) parse(Uint8List rawBytes) {
    if (rawBytes.length < minPacketSize) {
      return (false, 'Fehler: Paket zu kurz (${rawBytes.length} B)');
    }

    final data = ByteData.sublistView(rawBytes);
    final int magic = data.getUint32(0);
    if (magic != magicExpected) {
      return (
        false,
        'Ungültige Magic: 0x${magic.toRadixString(16).toUpperCase()}',
      );
    }

    final int version = data.getUint16(4);
    if (version != 1) {
      return (false, 'Nicht unterstützte Version: $version');
    }

    final int payloadSize = data.getUint32(6);
    if (payloadSize > maxPayloadSize) {
      return (false, 'Payload überschreitet Limit: $payloadSize B');
    }

    final int expectedTotal = minPacketSize + payloadSize;
    if (rawBytes.length < expectedTotal) {
      return (
        false,
        'Zu kurz ($expectedTotal B nötig, ${rawBytes.length} B da)',
      );
    }

    return (true, 'Paket OK: $payloadSize Bytes Nutzdaten');
  }
}

// Mutations-Engine für Property-Based Fuzzing
class FuzzingEngine {
  final math.Random _rnd = math.Random(1337);

  Uint8List erzeugeGueltigesPaket(int payloadLen) {
    final buffer = Uint8List(16 + payloadLen);
    final data = ByteData.sublistView(buffer);
    data.setUint32(0, 0x54555242); // 'TURB'
    data.setUint16(4, 1); // Version 1
    data.setUint32(6, payloadLen);
    data.setUint32(10, 0); // Reserviert
    data.setUint16(14, 0); // Flags
    for (int i = 0; i < payloadLen; i++) {
      buffer[16 + i] = (i + 1) & 0xFF;
    }
    return buffer;
  }

  Uint8List mutiere(Uint8List original) {
    final copy = Uint8List.fromList(original);
    if (copy.isEmpty) return copy;

    final int strategie = _rnd.nextInt(5);
    switch (strategie) {
      case 0: // Bitflip
        final int byteIdx = _rnd.nextInt(copy.length);
        final int bitIdx = _rnd.nextInt(8);
        copy[byteIdx] ^= (1 << bitIdx);
        break;
      case 1: // Zufälliges Byte überschreiben
        final int pos = _rnd.nextInt(copy.length);
        copy[pos] = _rnd.nextInt(256);
        break;
      case 2: // Abschneiden (Truncation)
        final int neueLaenge = _rnd.nextInt(copy.length);
        return Uint8List.sublistView(copy, 0, neueLaenge);
      case 3: // Grenzwert-Injektion (0xFFFFFFFF oder 0)
        if (copy.length >= 10) {
          final data = ByteData.sublistView(copy);
          final bool maxVal = _rnd.nextBool();
          data.setUint32(6, maxVal ? 0xFFFFFFFF : 0);
        }
        break;
      case 4: // Byte-Vertauschung (Shuffling)
        final int p1 = _rnd.nextInt(copy.length);
        final int p2 = _rnd.nextInt(copy.length);
        final int tmp = copy[p1];
        copy[p1] = copy[p2];
        copy[p2] = tmp;
        break;
    }
    return copy;
  }
}

void main() {
  runApp(const FuzzingApp());
}

class FuzzingApp extends StatelessWidget {
  const FuzzingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuzzing & Mutationsprüfung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FuzzingScreen(),
    );
  }
}

class FuzzingScreen extends StatefulWidget {
  const FuzzingScreen({super.key});

  @override
  State<FuzzingScreen> createState() => _FuzzingScreenState();
}

class _FuzzingScreenState extends State<FuzzingScreen> {
  final FuzzingEngine _fuzzer = FuzzingEngine();
  int _durchlaeufe = 0;
  int _abgelehnt = 0;
  int _akzeptiert = 0;
  int _crashes = 0;
  bool _laeuft = false;
  final List<String> _log = [];

  Future<void> _starteFuzzing(int anzahl) async {
    setState(() {
      _laeuft = true;
      _durchlaeufe = 0;
      _abgelehnt = 0;
      _akzeptiert = 0;
      _crashes = 0;
      _log.clear();
    });

    final basisPaket = _fuzzer.erzeugeGueltigesPaket(32);

    for (int i = 0; i < anzahl; i++) {
      final mutiert = _fuzzer.mutiere(basisPaket);
      try {
        final (ok, msg) = PaketParser.parse(mutiert);
        if (ok) {
          _akzeptiert++;
        } else {
          _abgelehnt++;
        }
        if (i < 5 || (!ok && _log.length < 15)) {
          _log.add('[$i] $msg');
        }
      } catch (e) {
        _crashes++;
        _log.add('[$i] CRASH: $e');
      }

      _durchlaeufe++;
      if (i % 250 == 0) {
        setState(() {});
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }

    setState(() {
      _laeuft = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('Fuzzing & Property-Based Testing'),
        backgroundColor: const Color(0xFF1E272C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsGrid(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _laeuft ? null : () => _starteFuzzing(1000),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('1.000 Mutationen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _laeuft ? null : () => _starteFuzzing(5000),
                    icon: const Icon(Icons.security),
                    label: const Text('5.000 Mutationen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Fuzzing Log (Stichproben & Fehler):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF80CBC4),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (context, idx) {
                    final line = _log[idx];
                    final bool isCrash = line.contains('CRASH');
                    return Text(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isCrash
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            titel: 'Durchläufe',
            wert: '$_durchlaeufe',
            farbe: const Color(0xFF00B0FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            titel: 'Abgelehnt',
            wert: '$_abgelehnt',
            farbe: const Color(0xFFFFB74D),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            titel: 'Akzeptiert',
            wert: '$_akzeptiert',
            farbe: const Color(0xFF81C784),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            titel: 'Crashes',
            wert: '$_crashes',
            farbe: _crashes == 0
                ? const Color(0xFF81C784)
                : const Color(0xFFEF5350),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String titel,
    required String wert,
    required Color farbe,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: farbe.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            titel,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            wert,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: farbe,
            ),
          ),
        ],
      ),
    );
  }
}
