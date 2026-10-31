import 'package:flutter/material.dart';

void main() {
  final String werkstattName = 'Flutter-Werkstatt';
  final int kapitelNummer = 4;
  final String autor = 'Volker';

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: Text(
            '$werkstattName\n'
            'Kapitel $kapitelNummer\n'
            'Gebaut von $autor',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
