import 'package:flutter/material.dart';
import '../models/kassette.dart';

class KassettenRegal extends StatelessWidget {
  final List<Kassette> kassetten;
  final Kassette? gewaehlteKassette;
  final ValueChanged<Kassette> onKassetteAusgewaehlt;

  const KassettenRegal({
    super.key,
    required this.kassetten,
    this.gewaehlteKassette,
    required this.onKassetteAusgewaehlt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF261810), // Dunkles Holz
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF451A03), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shelves, color: Color(0xFFFBBF24)),
                  SizedBox(width: 8),
                  Text(
                    'KASSETTENREGAL (ARCHIV)',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Text(
                '${kassetten.length} Tapes',
                style: const TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Holz-Regalbrett mit Kassettenruecken
          Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C110A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF3E1C0A)),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kassetten.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final k = kassetten[index];
                final istImDeck = k.id == gewaehlteKassette?.id;

                return GestureDetector(
                  onTap: () => onKassetteAusgewaehlt(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 78,
                    margin: EdgeInsets.only(bottom: istImDeck ? 12 : 0),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(k.farbcode),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: istImDeck
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF57534E),
                        width: istImDeck ? 2.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: istImDeck
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                              : Colors.black45,
                          blurRadius: istImDeck ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            k.bandtyp.split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          k.titel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '${k.dauerSekunden ~/ 60} Min',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
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
    );
  }
}
