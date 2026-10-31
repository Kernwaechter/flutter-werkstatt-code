import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFE2E8F0),
        body: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SneakerKarte(
                  kategorie: 'LAUFSCHUH · EDITION 2026',
                  modellName: 'CloudRunner Pro',
                  preis: '139,95 €',
                  bildHintergrund: Color(0xFFEFF6FF),
                ),
                SizedBox(width: 24),
                SneakerKarte(
                  kategorie: 'TRAIL-SCHUH · OUTDOOR',
                  modellName: 'GripMaster XT',
                  preis: '154,00 €',
                  bildHintergrund: Color(0xFFFEF3C7),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class GroessenKachel extends StatelessWidget {
  final String groesse;
  final bool istAusgewaehlt;

  const GroessenKachel({
    super.key,
    required this.groesse,
    this.istAusgewaehlt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: istAusgewaehlt
            ? const Color(0xFF1D4ED8)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          groesse,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: istAusgewaehlt
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class SneakerKarte extends StatelessWidget {
  final String kategorie;
  final String modellName;
  final String preis;
  final Color bildHintergrund;

  const SneakerKarte({
    super.key,
    required this.kategorie,
    required this.modellName,
    required this.preis,
    this.bildHintergrund = const Color(0xFFEFF6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bildHintergrund,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/sneaker.png',
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kategorie,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  modellName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    GroessenKachel(groesse: '40'),
                    SizedBox(width: 8),
                    GroessenKachel(groesse: '41'),
                    SizedBox(width: 8),
                    GroessenKachel(
                      groesse: '42',
                      istAusgewaehlt: true,
                    ),
                    SizedBox(width: 8),
                    GroessenKachel(groesse: '43'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sofort lieferbar',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Text(
                      preis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    child: const Text(
                      'In den Warenkorb',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
