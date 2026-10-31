import 'package:flutter/material.dart';

void main() => runApp(const Tag16App());

class Tag16App extends StatefulWidget {
  const Tag16App({super.key});

  @override
  State<Tag16App> createState() => _Tag16AppState();
}

class _Tag16AppState extends State<Tag16App> {
  double _wind = 0.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: GestureDetector(
          onPanUpdate: (d) {
            setState(() => _wind += d.delta.dx * 0.2);
          },
          child: Center(
            child: Text(
              'Aktueller Wind-Schwung: ${_wind.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
