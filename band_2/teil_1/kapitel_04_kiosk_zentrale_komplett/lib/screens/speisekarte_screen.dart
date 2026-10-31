import 'package:flutter/material.dart';
import '../models/snack.dart';
import '../widgets/snack_karte.dart';
import 'snack_detail_screen.dart';

class SpeisekarteScreen extends StatelessWidget {
  const SpeisekarteScreen({super.key});

  void oeffneDetails(BuildContext context, Snack snack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SnackDetailScreen(snack: snack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        title: const Text(
          'Pausen-Kiosk · Speisekarte',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: kioskSpeisekarte.length,
            itemBuilder: (context, index) {
              final Snack aktuellerSnack = kioskSpeisekarte[index];
              return SnackKarte(
                snack: aktuellerSnack,
                onTap: () => oeffneDetails(context, aktuellerSnack),
              );
            },
          ),
        ),
      ),
    );
  }
}
