import 'package:flutter/material.dart';

class ReleaseKonfiguration {
  final String appId;
  final String version;
  final int buildNummer;
  final bool istKeystoreGueltig;
  final bool istCiCdAktiv;
  final String signaturAlgorithmus;

  const ReleaseKonfiguration({
    required this.appId,
    required this.version,
    required this.buildNummer,
    required this.istKeystoreGueltig,
    required this.istCiCdAktiv,
    required this.signaturAlgorithmus,
  });
}

void main() {
  runApp(const StoreReleaseApp());
}

class StoreReleaseApp extends StatelessWidget {
  const StoreReleaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Release & CI/CD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ReleaseCheckScreen(),
    );
  }
}

class ReleaseCheckScreen extends StatefulWidget {
  const ReleaseCheckScreen({super.key});

  @override
  State<ReleaseCheckScreen> createState() =>
      _ReleaseCheckScreenState();
}

class _ReleaseCheckScreenState extends State<ReleaseCheckScreen> {
  final ReleaseKonfiguration _config = const ReleaseKonfiguration(
    appId: 'de.flutter_werkstatt.turbokrypto',
    version: '1.0.0',
    buildNummer: 100,
    istKeystoreGueltig: true,
    istCiCdAktiv: true,
    signaturAlgorithmus: 'SHA256withRSA (4096 Bit)',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('Store Release & CI/CD Pipeline'),
        backgroundColor: const Color(0xFF1E272C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 20),
            _buildInfoCard('App-Identifikation & Bundle', [
              'Application ID: ${_config.appId}',
              'SemVer Version: ${_config.version}',
              'Build-Nummer: ${_config.buildNummer}',
              'Target SDK: Android 34 / iOS 17',
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Kryptografische Signatur', [
              'Keystore: key.jks (Validiert ✓)',
              'Algorithmus: ${_config.signaturAlgorithmus}',
              'V1/V2/V3 Signatur: Vollständig aktiv',
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Automatisierung & Fastlane', [
              'GitHub Actions: .github/workflows/release.yml',
              'Fastlane Lane: fastlane android deploy_internal',
              'AOT Obfuscation: Split-Debug-Symbols verknüpft',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified,
            color: Color(0xFF81C784),
            size: 36,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Release-Status: Schluesselfertig bereit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Alle Store-Bundles signiert & CI/CD konfiguriert',
                  style: TextStyle(
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

  Widget _buildInfoCard(String titel, List<String> zeilen) {
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
}
