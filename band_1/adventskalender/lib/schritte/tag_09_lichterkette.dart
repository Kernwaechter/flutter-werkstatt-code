import 'package:flutter/material.dart';

void main() => runApp(const Tag09App());

class Tag09App extends StatefulWidget {
  const Tag09App({super.key});

  @override
  State<Tag09App> createState() => _Tag09AppState();
}

class _Tag09AppState extends State<Tag09App>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Center(
              child: CustomPaint(
                size: const Size(260, 260),
                painter: LichterPainter(pulsation: _ctrl.value),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LichterPainter extends CustomPainter {
  final double pulsation;
  LichterPainter({required this.pulsation});

  @override
  void paint(Canvas canvas, Size size) {
    final pos = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.solid,
        2.0 + pulsation * 4.0,
      );

    canvas.drawCircle(pos, 8, paint);
  }

  @override
  bool shouldRepaint(covariant LichterPainter oldDelegate) => true;
}
