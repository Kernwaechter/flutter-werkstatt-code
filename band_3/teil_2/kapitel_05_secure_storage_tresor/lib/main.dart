import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SecureStorageApp());
}

/// Datenmodell für einen gespeicherten Tresor-Eintrag.
class VaultSecret {
  final String key;
  final String title;
  final String account;
  final String value;
  final DateTime updatedAt;

  const VaultSecret({
    required this.key,
    required this.title,
    required this.account,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'account': account,
    'value': value,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory VaultSecret.fromJson(Map<String, dynamic> json) {
    return VaultSecret(
      key: json['key'] as String,
      title: json['title'] as String,
      account: json['account'] as String,
      value: json['value'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Demonstrations-Dienst für sicheren Schlüsselspeicher.
/// Kapselt den Keystore-Zugriff und verschlüsselt Einträge
/// mit einem abgeleiteten Master-Schlüssel.
class SafeStorageService {
  final Map<String, String> _secureKeystore = {};
  final String _masterSecret = 'Werkbank-Hardware-Salt-2026';

  String _encrypt(String plain) {
    final keyBytes = utf8.encode(_masterSecret);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode(plain));
    final encoded = base64Url.encode(utf8.encode(plain));
    // Speichere Prüfsumme vorangestellt
    return '${digest.toString().substring(0, 16)}:$encoded';
  }

  String? _decrypt(String encrypted) {
    final parts = encrypted.split(':');
    if (parts.length != 2) return null;
    final payloadBytes = base64Url.decode(parts[1]);
    final plain = utf8.decode(payloadBytes);
    final keyBytes = utf8.encode(_masterSecret);
    final hmac = Hmac(sha256, keyBytes);
    final expectedDigest = hmac.convert(payloadBytes).toString();
    if (!expectedDigest.startsWith(parts[0])) {
      throw const FormatException('HMAC-Integritätsfehler!');
    }
    return plain;
  }

  Future<void> writeSecret(VaultSecret secret) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final jsonStr = jsonEncode(secret.toJson());
    _secureKeystore[secret.key] = _encrypt(jsonStr);
  }

  Future<VaultSecret?> readSecret(String key) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final encrypted = _secureKeystore[key];
    if (encrypted == null) return null;
    final plain = _decrypt(encrypted);
    if (plain == null) return null;
    return VaultSecret.fromJson(
      jsonDecode(plain) as Map<String, dynamic>,
    );
  }

  Future<List<VaultSecret>> readAll() async {
    final list = <VaultSecret>[];
    for (final key in _secureKeystore.keys) {
      final s = await readSecret(key);
      if (s != null) list.add(s);
    }
    return list;
  }

  Future<void> deleteSecret(String key) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _secureKeystore.remove(key);
  }

  Future<void> clearAll() async {
    _secureKeystore.clear();
  }
}

class SecureStorageApp extends StatelessWidget {
  const SecureStorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyVault - Tresor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const SecureStorageHome(),
    );
  }
}

class SecureStorageHome extends StatefulWidget {
  const SecureStorageHome({super.key});

  @override
  State<SecureStorageHome> createState() => _SecureStorageHomeState();
}

class _SecureStorageHomeState extends State<SecureStorageHome> {
  final SafeStorageService _storage = SafeStorageService();
  final List<VaultSecret> _secrets = [];
  bool _isLocked = false;
  int _secondsUntilLock = 60;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _seedInitialSecrets();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    setState(() => _secondsUntilLock = 60);
    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
      if (_secondsUntilLock > 1) {
        setState(() => _secondsUntilLock--);
      } else {
        t.cancel();
        setState(() {
          _secondsUntilLock = 0;
          _isLocked = true;
        });
      }
    });
  }

  void _resetInactivity() {
    if (!_isLocked) {
      _startInactivityTimer();
    }
  }

  Future<void> _seedInitialSecrets() async {
    await _storage.writeSecret(
      VaultSecret(
        key: 'gh_token',
        title: 'GitHub Access Token',
        account: 'volker@werkstatt.de',
        value: 'ghp_7x9Q8zK3LmN2pA1w',
        updatedAt: DateTime.now(),
      ),
    );
    await _storage.writeSecret(
      VaultSecret(
        key: 'ssh_bastion',
        title: 'SSH Bastion Key',
        account: 'admin-prod',
        value: 'ed25519-secret-passphrase-99',
        updatedAt: DateTime.now(),
      ),
    );
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    final list = await _storage.readAll();
    setState(() => _secrets
      ..clear()
      ..addAll(list));
  }

  Future<void> _addNewSecret() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newSecret = VaultSecret(
      key: 'key_$id',
      title: 'Neuer API-Schlüssel',
      account: 'service_worker_$id',
      value: 'sec_${id.hashCode.toRadixString(16)}',
      updatedAt: DateTime.now(),
    );
    await _storage.writeSecret(newSecret);
    await _loadSecrets();
    _resetInactivity();
  }

  void _unlockVault() {
    setState(() => _isLocked = false);
    _resetInactivity();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 72,
                color: Color(0xFFE11D48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tresor automatisch gesperrt',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sicherheits-Timeout nach 60s Inaktivität',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _unlockVault,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Tresor entsperren'),
              ),
            ],
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _resetInactivity(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KeyVault – Hardware-Tresor'),
          backgroundColor: const Color(0xFF1E293B),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Auto-Lock: ${_secondsUntilLock}s',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _secrets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = _secrets[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          s.account,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wert: ${s.value}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFF94A3B8),
                    onPressed: () async {
                      await _storage.deleteSecret(s.key);
                      _loadSecrets();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addNewSecret,
          backgroundColor: const Color(0xFFE11D48),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Neuer Schlüssel'),
        ),
      ),
    );
  }
}
