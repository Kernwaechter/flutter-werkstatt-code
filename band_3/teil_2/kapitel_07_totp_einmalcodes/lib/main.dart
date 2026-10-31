import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const TotpApp());
}

/// Dekodiert Base32-Zeichenketten nach RFC 4648.
class Base32Decoder {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static Uint8List decode(String input) {
    final clean = input
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z2-7]'), '');
    var buffer = 0;
    var bitsLeft = 0;
    final output = <int>[];

    for (var i = 0; i < clean.length; i++) {
      final val = _alphabet.indexOf(clean[i]);
      if (val < 0) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        output.add((buffer >> bitsLeft) & 0xFF);
      }
    }
    return Uint8List.fromList(output);
  }
}

/// Reiner Dart TOTP-Generator nach RFC 6238.
class TotpEngine {
  /// Berechnet den 6-stelligen Code für ein Secret
  /// und einen optionalen Unix-Timestamp.
  static String generateCode({
    required String secretBase32,
    int? timestampMs,
    int intervalSeconds = 30,
  }) {
    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final timeStep = (now ~/ 1000) ~/ intervalSeconds;

    final keyBytes = Base32Decoder.decode(secretBase32);
    if (keyBytes.isEmpty) return '000000';

    // 8-Byte Big-Endian Zähler
    final counterBytes = Uint8List(8);
    var tempStep = timeStep;
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = tempStep & 0xFF;
      tempStep >>= 8;
    }

    // HMAC-SHA1
    final hmac = Hmac(sha1, keyBytes);
    final hash = hmac.convert(counterBytes).bytes;

    // Dynamische Kürzung (Dynamic Truncation)
    final offset = hash[hash.length - 1] & 0x0F;
    final binary =
        ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    final otp = binary % 1000000;
    return otp.toString().padLeft(6, '0');
  }

  /// Prüft einen Code mit Zeit-Drift Toleranz (+- 1 Zeitschritt).
  static bool verifyCode({
    required String enteredCode,
    required String secretBase32,
    int window = 1,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = -window; i <= window; i++) {
      final shiftedTime = now + (i * 30 * 1000);
      final validCode = generateCode(
        secretBase32: secretBase32,
        timestampMs: shiftedTime,
      );
      if (validCode == enteredCode) return true;
    }
    return false;
  }
}

/// Datenmodell für einen 2FA-Account.
class TotpAccount {
  final String title;
  final String username;
  final String secretBase32;

  const TotpAccount({
    required this.title,
    required this.username,
    required this.secretBase32,
  });
}

class TotpApp extends StatelessWidget {
  const TotpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOTP Einmalcodes (RFC 6238)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const TotpHome(),
    );
  }
}

class TotpHome extends StatefulWidget {
  const TotpHome({super.key});

  @override
  State<TotpHome> createState() => _TotpHomeState();
}

class _TotpHomeState extends State<TotpHome> {
  final List<TotpAccount> _accounts = [
    const TotpAccount(
      title: 'GitHub Security',
      username: 'volkerdaehn',
      // Standard Test-Secret RFC 6238 (128-bit)
      secretBase32: 'JBSWY3DPEHPK3PXP',
    ),
    const TotpAccount(
      title: 'AWS Root Console',
      username: 'admin@werkstatt.de',
      secretBase32: 'HXDMVJECJJWSRB3H',
    ),
    const TotpAccount(
      title: 'GitLab Deployment',
      username: 'ops-bot',
      secretBase32: 'MFRGGZDFMY======',
    ),
  ];

  late Timer _ticker;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _updateSeconds();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _updateSeconds());
    });
  }

  void _updateSeconds() {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _secondsLeft = 30 - (nowSeconds % 30);
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _addNewAccount() {
    setState(() {
      _accounts.add(
        const TotpAccount(
          title: 'Linux Bastion Host',
          username: 'root@datacenter',
          secretBase32: 'KRUGS4ZANFZSAYJA',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyVault – 2FA Einmalcodes'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / 30.0,
                    strokeWidth: 3,
                    backgroundColor: const Color(0xFF334155),
                    color: _secondsLeft < 6
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_secondsLeft}s',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final acc = _accounts[index];
          final rawCode = TotpEngine.generateCode(
            secretBase32: acc.secretBase32,
          );
          final formattedCode =
              '${rawCode.substring(0, 3)} ${rawCode.substring(3)}';

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        acc.username,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedCode,
                        style: TextStyle(
                          fontSize: 26,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: _secondsLeft < 6
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  color: const Color(0xFF38BDF8),
                  tooltip: 'Code kopieren',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Code $formattedCode kopiert!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAccount,
        backgroundColor: const Color(0xFFE11D48),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
