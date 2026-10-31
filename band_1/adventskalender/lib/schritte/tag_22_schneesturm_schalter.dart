import 'package:flutter/material.dart';

void main() => runApp(const Tag22App());

class Tag22App extends StatefulWidget {
  const Tag22App({super.key});

  @override
  State<Tag22App> createState() => _Tag22AppState();
}

class _Tag22AppState extends State<Tag22App> {
  bool _sturm = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _sturm ? Colors.red : Colors.blueGrey,
            ),
            icon: Icon(_sturm ? Icons.cyclone : Icons.ac_unit),
            label: Text(_sturm ? 'Sturm aktiv' : 'Schneesturm an'),
            onPressed: () => setState(() => _sturm = !_sturm),
          ),
        ),
      ),
    );
  }
}
