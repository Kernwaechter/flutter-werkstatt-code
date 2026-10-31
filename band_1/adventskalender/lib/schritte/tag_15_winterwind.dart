import 'package:flutter/material.dart';

void main() => runApp(const Tag15App());

class Tag15App extends StatelessWidget {
  const Tag15App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF070B19),
        body: Center(
          child: Text(
            'Wind-Drift: f.x += sin(phase + zeit) * 0.8',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
