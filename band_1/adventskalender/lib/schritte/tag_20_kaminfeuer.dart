import 'package:flutter/material.dart';

void main() => runApp(const Tag20App());

class Tag20App extends StatelessWidget {
  const Tag20App({super.key});

  @override
  Widget build(BuildContext context) {
    final feuer = Color.lerp(
      const Color(0xFFEF4444),
      const Color(0xFFFBBF24),
      0.65,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: feuer,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
