import 'dart:io';
import 'package:flutter/material.dart';

class DesktopPaketStatus {
  final String plattform;
  final String format;
  final String sandboxTyp;
  final List<String> berechtigungen;

  const DesktopPaketStatus({
    required this.plattform,
    required this.format,
    required this.sandboxTyp,
    required this.berechtigungen,
  });
}

void main() {
  runApp(const DesktopPaketApp());
}

class DesktopPaketApp extends StatelessWidget {
  const DesktopPaketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flatpak & Desktop Installer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DesktopScreen(),
    );
  }
}

class DesktopScreen extends StatelessWidget {
  const DesktopScreen({super.key});

  DesktopPaketStatus _ermittleStatus() {
    if (Platform.isLinux) {
      final bool inFlatpak =
          Platform.environment.containsKey('FLATPAK_ID');
      return DesktopPaketStatus(
        plattform: 'Linux (Tuxedo OS, Fedora, CachyOS)',
        format: inFlatpak
            ? 'Flatpak Sandbox'
            : 'Natives Linux Binary',
        sandboxTyp: inFlatpak
            ? 'Bwrap Sandbox (Streng isoliert)'
            : 'Host-Dateisystem',
        berechtigungen: [
          '--socket=wayland',
          '--socket=fallback-x11',
          '--share=ipc',
          '--share=network',
          'org.freedesktop.portal.Desktop',
        ],
      );
    } else if (Platform.isWindows) {
      return const DesktopPaketStatus(
        plattform: 'Microsoft Windows 11',
        format: 'MSIX Container Package',
        sandboxTyp: 'Centennial Container (AppContainer)',
        berechtigungen: [
          'runFullTrust',
          'internetClient',
          'privateNetworkClientServer',
        ],
      );
    } else {
      return const DesktopPaketStatus(
        plattform: 'Apple macOS',
        format: 'Universal DMG (Apple Silicon & Intel)',
        sandboxTyp: 'App Sandbox & Hardened Runtime',
        berechtigungen: [
          'com.apple.security.network.client',
          'com.apple.security.network.server',
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _ermittleStatus();

    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('Desktop-Installer: Flatpak & MSIX'),
        backgroundColor: const Color(0xFF1E272C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlatformHeader(status),
            const SizedBox(height: 20),
            _buildDetailsCard('Paketformat & Container', [
              'Aktive Plattform: ${status.plattform}',
              'Paket-Typ: ${status.format}',
              'Sicherheits-Sandbox: ${status.sandboxTyp}',
            ]),
            const SizedBox(height: 16),
            _buildPermissionsCard(status.berechtigungen),
            const SizedBox(height: 16),
            _buildManifestSnippet(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformHeader(DesktopPaketStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.desktop_windows,
              color: Color(0xFF81C784), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desktop-Ziel: ${status.plattform}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${status.format}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String titel, List<String> zeilen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF80CBC4),
            ),
          ),
          const Divider(height: 16, color: Color(0xFF2E3C43)),
          ...zeilen.map(
            (z) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                z,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(List<String> berechtigungen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sandbox-Berechtigungen (Portals & Sockets)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF80CBC4),
            ),
          ),
          const Divider(height: 16, color: Color(0xFF2E3C43)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: berechtigungen
                .map(
                  (b) => Chip(
                    label: Text(
                      b,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestSnippet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flatpak Manifest (turbokrypto.yml):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF38BDF8),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'app-id: de.flutter_werkstatt.turbokrypto\n'
            'runtime: org.freedesktop.Platform\n'
            'runtime-version: "23.08"\n'
            'sdk: org.freedesktop.Sdk\n'
            'command: turbokrypto',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
