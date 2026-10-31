import 'package:flutter/material.dart';
import 'screens/speisekarte_screen.dart';

void main() {
  runApp(const PausenKioskApp());
}

class PausenKioskApp extends StatelessWidget {
  const PausenKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pausen-Kiosk',
      home: SpeisekarteScreen(),
    );
  }
}
