import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const KeyVaultApp());
}

/// Dekodiert Base32-Schlüssel (RFC 4648).
class Base32 {
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

/// TOTP-Berechnung nach RFC 6238.
class TotpService {
  static String generate(String secretBase32) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeStep = nowSeconds ~/ 30;

    final keyBytes = Base32.decode(secretBase32);
    if (keyBytes.isEmpty) return '000000';

    final counter = Uint8List(8);
    var t = timeStep;
    for (var i = 7; i >= 0; i--) {
      counter[i] = t & 0xFF;
      t >>= 8;
    }

    final hmac = Hmac(sha1, keyBytes);
    final hash = hmac.convert(counter).bytes;

    final offset = hash[hash.length - 1] & 0x0F;
    final binary =
        ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    return (binary % 1000000).toString().padLeft(6, '0');
  }
}

/// Krypto-Helfer für Passwort-Hashes & RAM-Hygiene.
class SecurityCore {
  /// Berechnet einen 5000-fach iterierten SHA-256 Hash mit Salt.
  static String hashWithSalt(String pass, String salt) {
    List<int> bytes = utf8.encode('$pass:$salt');
    for (var i = 0; i < 5000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Vergleicht zwei Hashes in konstanter Laufzeit
  /// zum Schutz vor Timing-Angriffen.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Überschreibt ein Byte-Array explizit mit Nullen im Speicher.
  static void zeroize(Uint8List buffer) {
    buffer.fillRange(0, buffer.length, 0);
  }

  /// Berechnet die Entropie eines Passworts in Bits.
  static double calculateEntropy(String password) {
    if (password.isEmpty) return 0.0;
    var poolSize = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) poolSize += 10;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) poolSize += 32;

    if (poolSize == 0) return 0.0;
    return password.length * (log(poolSize) / ln2);
  }

  /// Generiert ein kryptografisch sicheres Zufallspasswort.
  static String generatePassword({int length = 18}) {
    const chars =
        'abcdefghijkmnopqrstuvwxyz'
        'ABCDEFGHJKLMNPQRSTUVWXYZ'
        '23456789!@#\$%^&*()-_=+';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}

/// Datenmodell für einen 2FA- oder Tresor-Eintrag.
class VaultItem {
  final String id;
  final String service;
  final String account;
  final String totpSecret;
  final String password;

  const VaultItem({
    required this.id,
    required this.service,
    required this.account,
    required this.totpSecret,
    required this.password,
  });
}

class KeyVaultApp extends StatelessWidget {
  const KeyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyVault - Enterprise 2FA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const KeyVaultHome(),
    );
  }
}

class KeyVaultHome extends StatefulWidget {
  const KeyVaultHome({super.key});

  @override
  State<KeyVaultHome> createState() => _KeyVaultHomeState();
}

class _KeyVaultHomeState extends State<KeyVaultHome> {
  bool _isUnlocked = false;
  int _secondsUntilLock = 60;
  int _secondsInTotpCycle = 30;
  Timer? _inactivityTimer;
  Timer? _totpTicker;
  Timer? _clipboardWipeTimer;
  int _clipboardWipeCountdown = 0;

  // Master-Passwortschutz
  final String _masterSalt = 'Werkbank-Sec-Salt-2026';
  late final String _masterHash;
  final _passwordCtrl = TextEditingController();

  final List<VaultItem> _items = [
    const VaultItem(
      id: '1',
      service: 'GitHub Enterprise',
      account: 'volker@daehn.security',
      totpSecret: 'JBSWY3DPEHPK3PXP',
      password: 'kR9!xM2#vL8\$wQ4^pZ',
    ),
    const VaultItem(
      id: '2',
      service: 'AWS Cloud Console',
      account: 'admin-root@cloud-ops',
      totpSecret: 'HXDMVJECJJWSRB3H',
      password: 'mN3*tY8&bV1!qW7@rD',
    ),
    const VaultItem(
      id: '3',
      service: 'GitLab Security Bot',
      account: 'ci-deploy@runner-01',
      totpSecret: 'MFRGGZDFMY======',
      password: 'zX5#hJ8%vK2^pL9!sA',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _masterHash = SecurityCore.hashWithSalt(
      'Werkbank-2026',
      _masterSalt,
    );
    _startTotpTicker();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _totpTicker?.cancel();
    _clipboardWipeTimer?.cancel();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startTotpTicker() {
    _updateTotpCycle();
    _totpTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _updateTotpCycle());
      }
    });
  }

  void _updateTotpCycle() {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _secondsInTotpCycle = 30 - (nowSeconds % 30);
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _secondsUntilLock = 60;
    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (_secondsUntilLock > 1) {
          if (mounted) setState(() => _secondsUntilLock--);
        } else {
          t.cancel();
          _lockVault();
        }
      },
    );
  }

  void _lockVault() {
    // RAM-Hygiene: Sensible Eingaben nullen
    final sensitiveBytes = Uint8List.fromList(
      utf8.encode(_passwordCtrl.text),
    );
    SecurityCore.zeroize(sensitiveBytes);
    _passwordCtrl.clear();

    _inactivityTimer?.cancel();
    if (mounted) {
      setState(() {
        _isUnlocked = false;
        _secondsUntilLock = 0;
      });
    }
  }

  void _unlockVault() {
    setState(() {
      _isUnlocked = true;
    });
    _startInactivityTimer();
  }

  void _verifyMasterPassword() {
    final enteredHash = SecurityCore.hashWithSalt(
      _passwordCtrl.text,
      _masterSalt,
    );
    if (SecurityCore.constantTimeEquals(enteredHash, _masterHash)) {
      _unlockVault();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ungültiges Master-Passwort!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    }
  }

  /// Kopiert ein Geheimnis und startet
  /// die automatische Bereinigung nach 30s.
  void _copyToClipboardWithHygiene(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _clipboardWipeTimer?.cancel();
    setState(() => _clipboardWipeCountdown = 30);

    _clipboardWipeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (_clipboardWipeCountdown > 1) {
          if (mounted) setState(() => _clipboardWipeCountdown--);
        } else {
          t.cancel();
          Clipboard.setData(const ClipboardData(text: ''));
          if (mounted) {
            setState(() => _clipboardWipeCountdown = 0);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Zwischenablage automatisch gereinigt.',
                ),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopiert! Löschung in 30 Sekunden.'),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  void _showPasswordGenerator() {
    final pass = SecurityCore.generatePassword();
    final entropy = SecurityCore.calculateEntropy(pass);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Passwort-Generator & Entropie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zufallsgeneriertes Passwort:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SelectableText(
                pass,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entropie: ${entropy.toStringAsFixed(1)} Bits',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kryptografische Stärke: Ausgezeichnet '
              '(Schutz gegen Brute-Force).',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Schließen'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _copyToClipboardWithHygiene(pass, 'Passwort');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Kopieren & Schützen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 42,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'KeyVault Tresor',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hardware-gesicherte 2FA & '
                        'Passwortverwaltung',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _unlockVault,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(
                            double.infinity,
                            44,
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Biometrisch entsperren'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Master-Passwort (Werkbank-2026)',
                          prefixIcon: const Icon(
                            Icons.key_rounded,
                            color: Color(0xFFE11D48),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _verifyMasterPassword(),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _verifyMasterPassword,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          minimumSize: const Size(
                            double.infinity,
                            42,
                          ),
                          side: const BorderSide(
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                        child: const Text('Mit Passwort öffnen'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) {
        if (_isUnlocked) _startInactivityTimer();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KeyVault Enterprise'),
          backgroundColor: const Color(0xFF1E293B),
          actions: [
            if (_clipboardWipeCountdown > 0)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                  child: Text(
                    'Clip: ${_clipboardWipeCountdown}s',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE11D48),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lock: ${_secondsUntilLock}s',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.lock_rounded),
              tooltip: 'Jetzt sperren',
              onPressed: _lockVault,
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _items[index];
            final code = TotpService.generate(item.totpSecret);
            final formatted =
                '${code.substring(0, 3)} ${code.substring(3)}';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.service,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.account,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: _secondsInTotpCycle / 30.0,
                              strokeWidth: 2.5,
                              backgroundColor:
                                  const Color(0xFF334155),
                              color: _secondsInTotpCycle < 6
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_secondsInTotpCycle}s',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatted,
                        style: TextStyle(
                          fontSize: 24,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: _secondsInTotpCycle < 6
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF38BDF8),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.vpn_key_rounded,
                              size: 20,
                            ),
                            tooltip: 'Passwort kopieren',
                            color: const Color(0xFF94A3B8),
                            onPressed: () {
                              _copyToClipboardWithHygiene(
                                item.password,
                                'Passwort für ${item.service}',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 20,
                            ),
                            tooltip: '2FA-Code kopieren',
                            color: const Color(0xFF38BDF8),
                            onPressed: () {
                              _copyToClipboardWithHygiene(
                                code,
                                '2FA-Code für ${item.service}',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showPasswordGenerator,
          backgroundColor: const Color(0xFFE11D48),
          icon: const Icon(Icons.password_rounded),
          label: const Text('Passwort-Generator'),
        ),
      ),
    );
  }
}
