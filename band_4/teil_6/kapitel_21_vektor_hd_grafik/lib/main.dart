import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF060910),
        body: GameWidget.controlled(gameFactory: VectorHdGame.new),
      ),
    ),
  );
}

class VectorHdGame extends FlameGame with TapCallbacks {
  double currentZoom = 1.0;
  final List<double> zoomLevels = [1.0, 2.0, 4.0, 8.0];
  int zoomIndex = 0;

  @override
  Color backgroundColor() => const Color(0xFF060810);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Vektor-Panzer in der Bildschirmmitte platzieren
    add(HdVectorTank(position: size / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    zoomIndex = (zoomIndex + 1) % zoomLevels.length;
    currentZoom = zoomLevels[zoomIndex];
    camera.viewfinder.zoom = currentZoom;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'HD-Vektor-Rendering (Aufloesungsunabhaengig)\n'
            'Aktueller Zoom: ${currentZoom}x\n'
            'Tippe auf den Bildschirm, um Zoom zu wechseln (1x-8x)',
        style: const TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }
}

class HdVectorTank extends PositionComponent {
  HdVectorTank({required Vector2 position})
      : super(
          position: position,
          size: Vector2(80, 80),
          anchor: Anchor.center,
        );

  double rotationAngle = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    rotationAngle += dt * 0.5;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(rotationAngle);

    // Ketten links und rechts
    final trackPaint = Paint()
      ..color = const Color(0xFF1E2838)
      ..style = PaintingStyle.fill;
    final trackBorder = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-36, -32, 14, 64),
        const Radius.circular(4),
      ),
      trackPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-36, -32, 14, 64),
        const Radius.circular(4),
      ),
      trackBorder,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, -32, 14, 64),
        const Radius.circular(4),
      ),
      trackPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, -32, 14, 64),
        const Radius.circular(4),
      ),
      trackBorder,
    );

    // Hauptchassis (Hexagon-Pfad)
    final bodyPath = Path()
      ..moveTo(0, -28)
      ..lineTo(20, -18)
      ..lineTo(20, 18)
      ..lineTo(0, 28)
      ..lineTo(-20, 18)
      ..lineTo(-20, -18)
      ..close();

    final bodyFill = Paint()
      ..color = const Color(0xFF0E1624)
      ..style = PaintingStyle.fill;
    final bodyGlow = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(bodyPath, bodyFill);
    canvas.drawPath(bodyPath, bodyGlow);

    // Geschuetzturm (rotierend)
    final turretPaint = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 12, turretPaint);

    // Kanonenrohr
    final barrelPaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, const Offset(0, -38), barrelPaint);

    canvas.restore();
  }
}
