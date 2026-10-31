import 'package:flutter/material.dart';

void main() => runApp(const Tag12App());

class Tag12App extends StatelessWidget {
  const Tag12App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, c) {
            return Container(
              color: const Color(0xFF0A132C),
              alignment: Alignment.center,
              child: Text(
                'Layout: ${c.maxWidth.toInt()} x '
                '${c.maxHeight.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
