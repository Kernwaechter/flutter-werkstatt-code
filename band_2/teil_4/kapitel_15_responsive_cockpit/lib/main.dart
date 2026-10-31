import 'package:flutter/material.dart';
import 'screens/cockpit_screen.dart';

void main() {
  runApp(const ResponsiveCockpitApp());
}

class ResponsiveCockpitApp extends StatelessWidget {
  const ResponsiveCockpitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Responsive Cockpit',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const CockpitScreen(),
    );
  }
}
