import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BiometrieApp());
}

/// Status der biometrischen Authentifizierung.
enum AuthStatus {
  locked,
  authenticating,
  authenticated,
  failed,
}

/// Krypto-Helfer für sichere Passwort-Prüfung.
class CryptoAuthHelper {
  /// Generiert ein kryptografisches Zufallssalz (16 Bytes als Hex).
  static String generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Berechnet einen iterierten PBKDF2-ähnlichen SHA-256 Hash.
  static String hashPassword(String password, String salt) {
    List<int> bytes = utf8.encode('$password:$salt');
    // 5000 Runden Iteration zur Dehnung (Key Stretching)
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
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

class BiometrieApp extends StatelessWidget {
  const BiometrieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biometrie & Fallback',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const BiometrieHome(),
    );
  }
}

class BiometrieHome extends StatefulWidget {
  const BiometrieHome({super.key});

  @override
  State<BiometrieHome> createState() => _BiometrieHomeState();
}

class _BiometrieHomeState extends State<BiometrieHome> {
  AuthStatus _status = AuthStatus.locked;
  String _statusMessage = 'Tresor gesperrt. Bitte authentifizieren.';
  int _failedAttempts = 0;

  // Festgelegtes Master-Passwort für die Demo: 'Werkbank-2026'
  late final String _salt;
  late final String _storedHash;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _salt = CryptoAuthHelper.generateSalt();
    _storedHash = CryptoAuthHelper.hashPassword(
      'Werkbank-2026',
      _salt,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _simulateBiometricScan() async {
    setState(() {
      _status = AuthStatus.authenticating;
      _statusMessage = 'Biometrischer Scan aktiv...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    // Simulation: 80% Erfolgsquote oder Knopfdruck
    final success = Random().nextInt(10) > 1;

    if (!mounted) return;

    if (success) {
      setState(() {
        _status = AuthStatus.authenticated;
        _failedAttempts = 0;
        _statusMessage = 'Erfolgreich entsperrt per Biometrie!';
      });
    } else {
      setState(() {
        _status = AuthStatus.failed;
        _failedAttempts++;
        _statusMessage =
            'Biometrie fehlgeschlagen ($failedAttempts/3). '
            'Nutze dein Master-Passwort.';
      });
    }
  }

  int get failedAttempts => _failedAttempts;

  void _verifyPassword(String entered) {
    final enteredHash = CryptoAuthHelper.hashPassword(entered, _salt);
    final isValid = CryptoAuthHelper.constantTimeEquals(
      enteredHash,
      _storedHash,
    );

    if (isValid) {
      setState(() {
        _status = AuthStatus.authenticated;
        _failedAttempts = 0;
        _statusMessage = 'Entsperrt per Master-Passwort!';
      });
      _passwordController.clear();
    } else {
      setState(() {
        _failedAttempts++;
        _status = AuthStatus.failed;
        _statusMessage =
            'Falsches Master-Passwort ($failedAttempts/3)!';
      });
    }
  }

  void _lockVault() {
    setState(() {
      _status = AuthStatus.locked;
      _statusMessage = 'Tresor manuell gesperrt.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = _status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyVault – Biometrie-Check'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          if (isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded),
              tooltip: 'Tresor sperren',
              onPressed: _lockVault,
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isUnlocked
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFF10B981).withValues(
                                alpha: 0.15,
                              )
                            : const Color(0xFFE11D48).withValues(
                                alpha: 0.15,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnlocked
                            ? Icons.verified_user_rounded
                            : Icons.fingerprint_rounded,
                        size: 48,
                        color: isUnlocked
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isUnlocked
                          ? 'Tresor Entsperrt'
                          : 'Sicherheits-Authentifizierung',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isUnlocked) ...[
                      ElevatedButton.icon(
                        onPressed:
                            _status == AuthStatus.authenticating
                                ? null
                                : _simulateBiometricScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(
                            double.infinity,
                            46,
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          _status == AuthStatus.authenticating
                              ? 'Prüfe Sensor...'
                              : 'Biometrisch entsperren',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(color: Color(0xFF334155)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: Text(
                              'ODER MASTER-PASSWORT',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Tipp: Werkbank-2026',
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
                        onSubmitted: _verifyPassword,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _verifyPassword(
                          _passwordController.text,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          minimumSize: const Size(
                            double.infinity,
                            44,
                          ),
                          side: const BorderSide(
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Passwort bestätigen'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF334155),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Geheimer Tresor-Schlüssel aktiv',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hardware-Token und Krypto-Schlüssel '
                              'im isolierten RAM geladen.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
