import 'package:flutter/material.dart';

void main() => runApp(const Tag18App());

class Tag18App extends StatefulWidget {
  const Tag18App({super.key});

  @override
  State<Tag18App> createState() => _Tag18AppState();
}

class _Tag18AppState extends State<Tag18App> {
  bool _tonAn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        appBar: AppBar(
          title: const Text('Akustik & Sound'),
          actions: [
            IconButton(
              icon: Icon(_tonAn ? Icons.volume_up : Icons.volume_off),
              onPressed: () => setState(() => _tonAn = !_tonAn),
            ),
          ],
        ),
        body: Center(
          child: Text(
            _tonAn ? 'Musik: Aktiv' : 'Musik: Stummgeschaltet',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
