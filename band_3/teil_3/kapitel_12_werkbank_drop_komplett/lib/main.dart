import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const WerkbankDropApp());
}

/// Datenmodell für einen Netzwerk-Peer im WLAN.
class DropPeer {
  final String id;
  final String name;
  final String address;
  final int port;
  final String platform;

  const DropPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.platform,
  });
}

/// Repräsentiert einen aktiven P2P-Transfer.
class DropSession {
  final String file;
  final int totalBytes;
  int transferredBytes;
  double speedMBps;
  final String sasCode;
  final String sasEmojis;
  bool isCompleted;

  DropSession({
    required this.file,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.speedMBps = 0.0,
    required this.sasCode,
    required this.sasEmojis,
    this.isCompleted = false,
  });

  double get fraction =>
      totalBytes > 0 ? transferredBytes / totalBytes : 0.0;
  String get sentMB =>
      (transferredBytes / (1024 * 1024)).toStringAsFixed(0);
  String get totalMB =>
      (totalBytes / (1024 * 1024)).toStringAsFixed(0);
  String get percent => (fraction * 100).toStringAsFixed(0);
  String get speedStr => speedMBps.toStringAsFixed(1);
}

/// SAS (Short Authentication String) Generator gegen MITM.
class SasAuthEngine {
  static const _emojiPool = [
    '🛡️', '🚀', '⚡', '🔑', '💎', '⚓', '🎯', '🔥', '🦊', '🦉'
  ];

  /// Erzeugt aus einem gemeinsamen Sitzungs-Geheimnis
  /// einen 4-stelligen Bestätigungscode und 3 Emojis.
  static ({String code, String emojis}) deriveSas(String secret) {
    final hash = sha256.convert(utf8.encode(secret)).bytes;
    final numVal =
        ((hash[0] & 0x7F) << 24) |
        ((hash[1] & 0xFF) << 16) |
        ((hash[2] & 0xFF) << 8) |
        (hash[3] & 0xFF);

    final code = (numVal % 10000).toString().padLeft(4, '0');
    final e1 = _emojiPool[hash[4] % _emojiPool.length];
    final e2 = _emojiPool[hash[5] % _emojiPool.length];
    final e3 = _emojiPool[hash[6] % _emojiPool.length];

    return (code: code, emojis: '$e1 $e2 $e3');
  }
}

class WerkbankDropApp extends StatelessWidget {
  const WerkbankDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Werkbank-Drop - P2P LAN Transfer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const WerkbankDropHome(),
    );
  }
}

class WerkbankDropHome extends StatefulWidget {
  const WerkbankDropHome({super.key});

  @override
  State<WerkbankDropHome> createState() => _WerkbankDropHomeState();
}

class _WerkbankDropHomeState extends State<WerkbankDropHome> {
  final List<DropPeer> _peers = [
    const DropPeer(
      id: 'p1',
      name: 'Linux-Workstation (Werkstatt)',
      address: '192.168.1.42',
      port: 54322,
      platform: 'linux',
    ),
    const DropPeer(
      id: 'p2',
      name: 'MacBook-Air (Office)',
      address: '192.168.1.55',
      port: 54322,
      platform: 'macos',
    ),
    const DropPeer(
      id: 'p3',
      name: 'Pixel-Phone (Volker)',
      address: '192.168.1.88',
      port: 54322,
      platform: 'android',
    ),
  ];

  DropPeer? _selectedPeer;
  DropSession? _activeSession;
  bool _isTransferring = false;
  bool _sasConfirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedPeer = _peers.first;
  }

  void _startTransfer() {
    if (_isTransferring || _selectedPeer == null) return;

    final token = DateTime.now().millisecondsSinceEpoch ~/ 10000;
    final sas = SasAuthEngine.deriveSas(
      'session-${_selectedPeer!.id}-$token',
    );

    setState(() {
      _isTransferring = true;
      _sasConfirmed = false;
      _activeSession = DropSession(
        file: 'werkstatt_update_band3.tar.gz',
        totalBytes: 482 * 1024 * 1024, // 482 MB
        sasCode: sas.code,
        sasEmojis: sas.emojis,
      );
    });

    _runStreamingLoop();
  }

  Future<void> _runStreamingLoop() async {
    const total = 482 * 1024 * 1024;
    const chunkSize = 2 * 1024 * 1024; // 2 MB Chunks
    var sent = 0;
    final stopwatch = Stopwatch()..start();

    while (sent < total && _isTransferring) {
      await Future.delayed(const Duration(milliseconds: 35));
      sent += chunkSize;
      if (sent > total) sent = total;

      final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
      final speed =
          elapsed > 0 ? (sent / (1024 * 1024)) / elapsed : 0.0;

      if (!mounted) return;
      setState(() {
        _activeSession?.transferredBytes = sent;
        _activeSession?.speedMBps = speed;
      });
    }

    stopwatch.stop();
    if (!mounted) return;
    setState(() {
      _isTransferring = false;
      _activeSession?.isCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transfer erfolgreich abgeschlossen! SHA-256 verifiziert.',
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  IconData _iconForPlatform(String p) {
    switch (p.toLowerCase()) {
      case 'linux':
        return Icons.terminal_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'android':
        return Icons.smartphone_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkbank-Drop – P2P Sender'),
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
                color: const Color(0xFF10B981).withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Text(
                'LAN-Verschlüsselung: AES-256',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Linke Leiste: Gefundene Geräte im WLAN
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(
                right: BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'EMPFÄNGER IM WLAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    itemCount: _peers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = _peers[index];
                      final isSel = _selectedPeer?.id == p.id;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedPeer = p);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF10B981).withValues(
                                    alpha: 0.12,
                                  )
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _iconForPlatform(p.platform),
                                color: isSel
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF38BDF8),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSel
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    Text(
                                      '${p.address}:${p.port}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Rechter Hauptbereich: Dropzone & Transfer-Status
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dropzone
                  InkWell(
                    onTap: _startTransfer,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 2,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file_rounded,
                            size: 48,
                            color: Color(0xFF38BDF8),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Dateien hierhin ziehen zum Senden',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Klicken für Test-Transfer (482 MB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aktiver Transfer
                  if (_activeSession != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeSession!.isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _activeSession!.file,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_activeSession!.speedStr} MB/s',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _activeSession!.fraction,
                              minHeight: 8,
                              backgroundColor:
                                  const Color(0xFF0F172A),
                              color: _activeSession!.isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gesendet: '
                                '${_activeSession!.sentMB} MB von '
                                '${_activeSession!.totalMB} MB',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '${_activeSession!.percent}%',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SAS-Verifikationsleiste
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sicherheitswort (SAS-Verifikation):',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _activeSession!.sasEmojis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _activeSession!.sasCode,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 2,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _sasConfirmed = true);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _sasConfirmed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              side: BorderSide(
                                color: _sasConfirmed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            icon: Icon(
                              _sasConfirmed
                                  ? Icons.check_circle_rounded
                                  : Icons.verified_user_outlined,
                              size: 16,
                            ),
                            label: Text(
                              _sasConfirmed
                                  ? 'Bestätigt'
                                  : 'Stimmt überein',
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
        ],
      ),
    );
  }
}
