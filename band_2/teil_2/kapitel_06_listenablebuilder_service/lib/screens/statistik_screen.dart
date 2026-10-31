import 'package:flutter/material.dart';
import '../controllers/medien_controller.dart';
import '../services/statistik_service.dart';

class StatistikScreen extends StatelessWidget {
  final MedienController controller;
  final StatistikService statistikService = const StatistikService();

  const StatistikScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text('Lese- & Medien-Statistik'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final int lesestunden =
              statistikService.berechneLesestunden(controller.medien);
          final double schnitt =
              statistikService.berechneDurchschnittsSterne(controller.medien);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatistikKachel(
                  titel: 'Geschätzte Zeit investiert',
                  wert: '$lesestunden Stunden',
                  untertitel: 'Basiert auf Buchseiten und Podcast-Minuten',
                  icon: Icons.timer_outlined,
                  farbe: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 16),
                _StatistikKachel(
                  titel: 'Durchschnittliche Bewertung',
                  wert: '${schnitt.toStringAsFixed(1)} von 5 Sternen',
                  untertitel: 'Über alle ${controller.anzahlGesamt} Einträge',
                  icon: Icons.star_rate_rounded,
                  farbe: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                _StatistikKachel(
                  titel: 'Favoriten-Quote',
                  wert: controller.anzahlGesamt > 0
                      ? '${((controller.anzahlFavoriten / controller.anzahlGesamt) * 100).round()}%'
                      : '0%',
                  untertitel:
                      '${controller.anzahlFavoriten} besondere Highlights',
                  icon: Icons.favorite,
                  farbe: const Color(0xFFEF4444),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatistikKachel extends StatelessWidget {
  final String titel;
  final String wert;
  final String untertitel;
  final IconData icon;
  final Color farbe;

  const _StatistikKachel({
    required this.titel,
    required this.wert,
    required this.untertitel,
    required this.icon,
    required this.farbe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: farbe.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: farbe, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wert,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  untertitel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
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
