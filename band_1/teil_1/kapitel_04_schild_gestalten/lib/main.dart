import 'package:flutter/material.dart';

void main() {
  final String werkstattName = 'Flutter-Werkstatt';
  final int kapitelNummer = 4;
  final double version = 1.0;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: Center(
          child: Text(
            'Willkommen in der $werkstattName!\n'
            'Kapitel $kapitelNummer · Version $version',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
