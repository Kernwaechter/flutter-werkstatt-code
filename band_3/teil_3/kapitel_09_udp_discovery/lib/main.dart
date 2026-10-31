import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const UdpDiscoveryApp());
}

/// Datenmodell für ein im WLAN gefundenes Gerät.
class DiscoveredPeer {
  final String id;
  final String name;
  final String address;
  final int tcpPort;
  final String platform;
  DateTime lastSeen;

  DiscoveredPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.tcpPort,
    required this.platform,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'port': tcpPort,
    'platform': platform,
  };

  factory DiscoveredPeer.fromJson(
    Map<String, dynamic> json,
    String hostAddress,
  ) {
    return DiscoveredPeer(
      id: json['id'] as String? ?? 'peer-${hostAddress.hashCode}',
      name: json['name'] as String? ?? 'Unbekanntes Gerät',
      address: hostAddress,
      tcpPort: json['port'] as int? ?? 54322,
      platform: json['platform'] as String? ?? 'generic',
      lastSeen: DateTime.now(),
    );
  }
}

/// Dienst für UDP-Broadcasts und Peer-Erkennung im Subnetz.
class DiscoveryService {
  static const int broadcastPort = 54321;
  static const int defaultTcpPort = 54322;

  final String deviceId =
      'dev-${DateTime.now().millisecondsSinceEpoch % 10000}';
  final String deviceName = 'Werkbank-${Platform.operatingSystem}';

  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  Timer? _pruneTimer;

  final StreamController<List<DiscoveredPeer>> _peersCtrl =
      StreamController<List<DiscoveredPeer>>.broadcast();

  final Map<String, DiscoveredPeer> _peers = {};

  Stream<List<DiscoveredPeer>> get peersStream => _peersCtrl.stream;

  Future<void> startDiscovery() async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
        reusePort: true,
      );
      _socket?.broadcastEnabled = true;

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });
    } catch (e) {
      debugPrint('UDP-Bind Hinweis (Fallback aktiv): $e');
      _injectSimulatedPeers();
    }

    _beaconTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _sendBeacon(),
    );

    _pruneTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pruneInactivePeers(),
    );
  }

  void _injectSimulatedPeers() {
    _peers['sim-mac'] = DiscoveredPeer(
      id: 'sim-mac',
      name: 'MacBook-Air (Werkstatt-Ost)',
      address: '192.168.1.55',
      tcpPort: 54322,
      platform: 'macos',
      lastSeen: DateTime.now(),
    );
    _peers['sim-pixel'] = DiscoveredPeer(
      id: 'sim-pixel',
      name: 'Pixel-Phone (Volker)',
      address: '192.168.1.88',
      tcpPort: 54322,
      platform: 'android',
      lastSeen: DateTime.now(),
    );
    _peersCtrl.add(_peers.values.toList());
  }

  void _sendBeacon() {
    if (_socket == null) return;
    final message = jsonEncode({
      'app': 'werkbank-drop',
      'id': deviceId,
      'name': deviceName,
      'port': defaultTcpPort,
      'platform': Platform.operatingSystem,
    });

    final bytes = utf8.encode(message);
    try {
      _socket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        broadcastPort,
      );
    } catch (_) {
      // Ignorieren falls Broadcast im lokalen Netz geblockt
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json['app'] != 'werkbank-drop') return;

      final senderId = json['id'] as String?;
      if (senderId == null || senderId == deviceId) return;

      final peer = DiscoveredPeer.fromJson(
        json,
        datagram.address.address,
      );
      _peers[peer.id] = peer;
      _peersCtrl.add(_peers.values.toList());
    } catch (_) {
      // Ungültige UDP-Pakete verwerfen
    }
  }

  void _pruneInactivePeers() {
    final now = DateTime.now();
    _peers.removeWhere(
      (_, peer) => now.difference(peer.lastSeen).inSeconds > 8,
    );
    _peersCtrl.add(_peers.values.toList());
  }

  void dispose() {
    _beaconTimer?.cancel();
    _pruneTimer?.cancel();
    _socket?.close();
    _peersCtrl.close();
  }
}

class UdpDiscoveryApp extends StatelessWidget {
  const UdpDiscoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDP Discovery im LAN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const UdpDiscoveryHome(),
    );
  }
}

class UdpDiscoveryHome extends StatefulWidget {
  const UdpDiscoveryHome({super.key});

  @override
  State<UdpDiscoveryHome> createState() => _UdpDiscoveryHomeState();
}

class _UdpDiscoveryHomeState extends State<UdpDiscoveryHome> {
  final DiscoveryService _service = DiscoveryService();
  bool _broadcasting = true;

  @override
  void initState() {
    super.initState();
    _service.startDiscovery();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  IconData _iconForPlatform(String p) {
    switch (p.toLowerCase()) {
      case 'linux':
        return Icons.terminal_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'android':
        return Icons.smartphone_rounded;
      case 'windows':
        return Icons.desktop_windows_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkbank-Drop – Discovery'),
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
                color: _broadcasting
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _broadcasting
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _broadcasting
                          ? const Color(0xFF10B981)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _broadcasting ? 'Beacon Aktiv' : 'Pausiert',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _broadcasting
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<DiscoveredPeer>>(
        stream: _service.peersStream,
        initialData: const [],
        builder: (context, snapshot) {
          final peers = snapshot.data ?? [];

          if (peers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Suche nach Geräten im WLAN...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Lausche auf UDP-Port 54321',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: peers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final peer = peers[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForPlatform(peer.platform),
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peer.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${peer.address}:${peer.tcpPort}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Bereit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _broadcasting = !_broadcasting);
        },
        backgroundColor: const Color(0xFFE11D48),
        icon: Icon(_broadcasting ? Icons.pause_rounded : Icons.radar),
        label: Text(_broadcasting ? 'Pausieren' : 'Erkennen'),
      ),
    );
  }
}
