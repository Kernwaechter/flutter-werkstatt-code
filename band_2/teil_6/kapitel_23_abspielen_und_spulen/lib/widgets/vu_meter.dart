import 'package:flutter/material.dart';

class StereoVuMeter extends StatelessWidget {
  final double pegelLinks; // 0.0 bis 1.0
  final double pegelRechts; // 0.0 bis 1.0
  final int? peakLinks; // Index 0..15
  final int? peakRechts; // Index 0..15

  const StereoVuMeter({
    super.key,
    required this.pegelLinks,
    required this.pegelRechts,
    this.peakLinks,
    this.peakRechts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PEAK LEVEL METER',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'dB',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _baueKanalZeile('L', pegelLinks, peakLinks),
          const SizedBox(height: 8),
          _baueKanalZeile('R', pegelRechts, peakRechts),
          const SizedBox(height: 8),
          // Skalenbeschriftung
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 20), // Platz fuer 'L' / 'R'
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('-20',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 9)),
                    Text('-10',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 9)),
                    Text('-5',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 9)),
                    Text('-3',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 9)),
                    Text('0',
                        style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Text('+3',
                        style: TextStyle(
                            color: Color(0xFFEF4444), fontSize: 9)),
                    Text('+6',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _baueKanalZeile(String kanal, double pegel, int? peakIndex) {
    const int gesamtSegmente = 16;
    final aktiveSegmente =
        (pegel.clamp(0.0, 1.0) * gesamtSegmente).round();

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            kanal,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(gesamtSegmente, (i) {
              final istAktiv = i < aktiveSegmente;
              final istPeak = i == peakIndex;

              Color farbe;
              if (i < 10) {
                farbe = const Color(0xFF10B981); // Gruen bis -3 dB
              } else if (i < 13) {
                farbe = const Color(0xFFF59E0B); // Gelb um 0 dB
              } else {
                farbe = const Color(0xFFEF4444); // Rot ueber 0 dB
              }

              return Expanded(
                child: Container(
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: (istAktiv || istPeak)
                        ? farbe
                        : farbe.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: (istAktiv || istPeak)
                        ? [
                            BoxShadow(
                              color: farbe.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
