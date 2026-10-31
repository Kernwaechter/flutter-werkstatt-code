import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/medien_liste_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MedienLogbuchApp(),
    ),
  );
}

class MedienLogbuchApp extends StatelessWidget {
  const MedienLogbuchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medien-Logbuch (Riverpod)',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0284C7),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const MedienListeScreen(),
    );
  }
}
