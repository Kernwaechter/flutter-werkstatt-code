import 'package:flutter/material.dart';

class FdroidAuditCheck {
  final String kriterium;
  final bool erfuellt;
  final String details;

  const FdroidAuditCheck({
    required this.kriterium,
    required this.erfuellt,
    required this.details,
  });
}

void main() {
  runApp(const FdroidApp());
}

class FdroidApp extends StatelessWidget {
  const FdroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F-Droid & Reproducible Builds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FdroidAuditScreen(),
    );
  }
}

class FdroidAuditScreen extends StatelessWidget {
  const FdroidAuditScreen({super.key});

  static const List<FdroidAuditCheck> _checks = [
    FdroidAuditCheck(
      kriterium: '100% Freier Open-Source-Code (FLOSS)',
      erfuellt: true,
      details: 'Keine proprietären Bibliotheken oder Blobs im Build',
    ),
    FdroidAuditCheck(
      kriterium: 'Keine Google Play Services Abhängigkeit',
      erfuellt: true,
      details: 'FOSS-Schnittstellen für Push & Lokalisierung',
    ),
    FdroidAuditCheck(
      kriterium: 'Keine Werbe- oder Tracking-SDKs',
      erfuellt: true,
      details: 'Frei von Firebase, Crashlytics oder Werbenetzen',
    ),
    FdroidAuditCheck(
      kriterium: 'Reproducible Build Verifikation',
      erfuellt: true,
      details: 'Bit-für-Bit identischer SHA-256 Hash aus dem Git-Tag',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('F-Droid & Freie Distribution'),
        backgroundColor: const Color(0xFF1E272C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 20),
            const Text(
              'F-Droid Inklusions-Kriterien:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF80CBC4),
              ),
            ),
            const SizedBox(height: 12),
            ..._checks.map((c) => _buildCheckTile(c)),
            const SizedBox(height: 20),
            _buildReproducibleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50)),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco, color: Color(0xFF81C784), size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'F-Droid Audit: Vollständig konform ✓',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bereit für das F-Droid Haupt-Repository',
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

  Widget _buildCheckTile(FdroidAuditCheck check) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF81C784),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.kriterium,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  check.details,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReproducibleCard() {
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
            'Reproduzierbare Prüfsumme (SHA-256):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF38BDF8),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '8f4a21b3c990de88421a... == 8f4a21b3c990de88421a...\n'
            'Status: Bit-für-Bit identisch verifiziert.',
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
