import 'package:flutter/material.dart';
import 'screens/tresor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SammlungsTresorApp());
}

class SammlungsTresorApp extends StatelessWidget {
  const SammlungsTresorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tresor Migration V2 & Backup',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0284C7),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const TresorScreen(),
    );
  }
}
