import 'package:flutter/material.dart';

void main() => runApp(const Tag01App());

class Tag01App extends StatelessWidget {
  const Tag01App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Mitternachtshimmel(),
      ),
    );
  }
}

class Mitternachtshimmel extends StatelessWidget {
  const Mitternachtshimmel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF040714), // Nachtschwarz im Zenit
            Color(0xFF0A132C), // Tiefes Nachtblau
            Color(0xFF162544), // Horizontblau
          ],
        ),
      ),
    );
  }
}
