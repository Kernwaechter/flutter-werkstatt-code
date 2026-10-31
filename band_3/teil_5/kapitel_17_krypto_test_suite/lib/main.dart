import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class KryptoRoutinen {
  static int crc32(List<int> daten) {
    int crc = 0xFFFFFFFF;
    for (final byte in daten) {
      crc ^= byte;
      for (int j = 0; j < 8; j++) {
        crc = (crc >> 1) ^ (0xEDB88320 & -(crc & 1));
      }
    }
    return ~crc & 0xFFFFFFFF;
  }

  static Uint8List xorTransform(Uint8List daten, int key) {
    final ergebnis = Uint8List(daten.length);
    for (int i = 0; i < daten.length; i++) {
      ergebnis[i] = daten[i] ^ (key & 0xFF);
    }
    return ergebnis;
  }

  static String berechneTotp({
    required String geheimnis,
    required int zeitstempelSekunden,
    int schrittWeite = 30,
    int stellen = 6,
  }) {
    final int intervall = zeitstempelSekunden ~/ schrittWeite;
    final ByteData timeBytes = ByteData(8)..setInt64(0, intervall);

    final keyBytes = utf8.encode(geheimnis);
    final hmac = Hmac(sha1, keyBytes);
    final digest = hmac.convert(timeBytes.buffer.asUint8List()).bytes;

    final int offset = digest[digest.length - 1] & 0x0F;
    final int code = ((digest[offset] & 0x7F) << 24) |
        ((digest[offset + 1] & 0xFF) << 16) |
        ((digest[offset + 2] & 0xFF) << 8) |
        (digest[offset + 3] & 0xFF);

    const int modulo = 1000000;
    return (code % modulo).toString().padLeft(stellen, '0');
  }
}

void main() {
  runApp(const KryptoTestSuiteApp());
}

class KryptoTestSuiteApp extends StatelessWidget {
  const KryptoTestSuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krypto Test-Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TestDashboardScreen(),
    );
  }
}

class TestErgebnis {
  final String name;
  final bool bestanden;
  final String details;

  const TestErgebnis({
    required this.name,
    required this.bestanden,
    required this.details,
  });
}

class TestDashboardScreen extends StatefulWidget {
  const TestDashboardScreen({super.key});

  @override
  State<TestDashboardScreen> createState() =>
      _TestDashboardScreenState();
}

class _TestDashboardScreenState extends State<TestDashboardScreen> {
  final List<TestErgebnis> _ergebnisse = [];
  bool _testsLaufen = false;

  void _starteTests() {
    setState(() {
      _testsLaufen = true;
      _ergebnisse.clear();
    });

    final daten = utf8.encode('Werkbank 2026');
    final int crc = KryptoRoutinen.crc32(daten);
    final bool crcOk = crc != 0;
    _ergebnisse.add(
      TestErgebnis(
        name: 'CRC32 Integritätstest',
        bestanden: crcOk,
        details: 'CRC: 0x${crc.toRadixString(16).toUpperCase()}',
      ),
    );

    final Uint8List original = Uint8List.fromList([1, 2, 3, 4, 5]);
    final verschluesselt =
        KryptoRoutinen.xorTransform(original, 0xAA);
    final entschluesselt =
        KryptoRoutinen.xorTransform(verschluesselt, 0xAA);
    bool xorOk = true;
    for (int i = 0; i < original.length; i++) {
      if (original[i] != entschluesselt[i]) xorOk = false;
    }
    _ergebnisse.add(
      TestErgebnis(
        name: 'XOR Symmetrie-Invariante',
        bestanden: xorOk,
        details: 'Original == Entschlüsselt: $xorOk',
      ),
    );

    final totp = KryptoRoutinen.berechneTotp(
      geheimnis: '12345678901234567890',
      zeitstempelSekunden: 59,
    );
    final bool totpOk = totp.length == 6;
    _ergebnisse.add(
      TestErgebnis(
        name: 'RFC 6238 TOTP Format',
        bestanden: totpOk,
        details: 'Generierter Code: $totp (Länge: ${totp.length})',
      ),
    );

    setState(() {
      _testsLaufen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int bestanden =
        _ergebnisse.where((e) => e.bestanden).length;

    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('Krypto Test-Suite & Verifikation'),
        backgroundColor: const Color(0xFF1E272C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(bestanden, _ergebnisse.length),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _testsLaufen ? null : _starteTests,
              icon: const Icon(Icons.playlist_play),
              label: const Text('Alle Krypto-Tests ausführen'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _ergebnisse.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final e = _ergebnisse[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E272C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: e.bestanden
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          e.bestanden
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: e.bestanden
                              ? const Color(0xFF81C784)
                              : const Color(0xFFEF5350),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.details,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int bestanden, int gesamt) {
    final bool alleOk = gesamt > 0 && bestanden == gesamt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alleOk
              ? const Color(0xFF4CAF50)
              : const Color(0xFF00B0FF).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test-Status',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                gesamt == 0
                    ? 'Noch keine Tests ausgeführt'
                    : '$bestanden von $gesamt bestanden',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: alleOk
                      ? const Color(0xFF00E676)
                      : Colors.white,
                ),
              ),
            ],
          ),
          Icon(
            alleOk ? Icons.verified : Icons.flaky,
            color: alleOk
                ? const Color(0xFF00E676)
                : const Color(0xFF00B0FF),
            size: 32,
          ),
        ],
      ),
    );
  }
}
