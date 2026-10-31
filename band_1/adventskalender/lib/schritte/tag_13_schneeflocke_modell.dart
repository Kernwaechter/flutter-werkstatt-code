import 'package:flutter/material.dart';

void main() => runApp(const Tag13App());

class Schneeflocke {
  double x;
  double y;
  double radius;
  double geschwindigkeit;
  double taumelPhase;

  Schneeflocke({
    required this.x,
    required this.y,
    required this.radius,
    required this.geschwindigkeit,
    required this.taumelPhase,
  });
}

class Tag13App extends StatelessWidget {
  const Tag13App({super.key});

  @override
  Widget build(BuildContext context) {
    final f = Schneeflocke(
      x: 100,
      y: 50,
      radius: 2.5,
      geschwindigkeit: 1.2,
      taumelPhase: 0.5,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: Text(
            'Flocke initialisiert: '
            'R=${f.radius}, V=${f.geschwindigkeit}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
