import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const Tag04App());

class Tag04App extends StatelessWidget {
  const Tag04App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SternenBlick(),
      ),
    );
  }
}

class SternenBlick extends StatefulWidget {
  const SternenBlick({super.key});

  @override
  State<SternenBlick> createState() => _SternenBlickState();
}

class _SternenBlickState extends State<SternenBlick>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: SternePainter(zeit: _ctrl.value * 2 * math.pi),
        );
      },
    );
  }
}

class SternePainter extends CustomPainter {
  final double zeit;
  SternePainter({required this.zeit});

  @override
  void paint(Canvas canvas, Size size) {
    // Fester Seed = stabile Positionen
    final zufall = math.Random(101);
    final paint = Paint();

    for (int i = 0; i < 50; i++) {
      final sx = zufall.nextDouble() * size.width;
      final sy = zufall.nextDouble() * (size.height * 0.5);
      final r = 0.8 + zufall.nextDouble() * 1.5;
      final funkeln = (math.sin(zeit + i) + 1) / 2;

      paint.color = Colors.white.withValues(
        alpha: 0.25 + 0.65 * funkeln,
      );
      canvas.drawCircle(Offset(sx, sy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SternePainter oldDelegate) => true;
}
