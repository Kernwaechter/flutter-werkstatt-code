import 'package:flutter/material.dart';

void main() => runApp(const Tag23App());

class Tag23App extends StatelessWidget {
  const Tag23App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF070B19),
        body: Center(
          child: Text(
            '★ Frohe Weihnachten & Gut Code! ★',
            style: TextStyle(
              color: Color(0xFFFEF3C7),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
