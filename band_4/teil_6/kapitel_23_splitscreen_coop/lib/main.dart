import 'dart:math';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF060810),
        body: GameWidget.controlled(gameFactory: SplitscreenGame.new),
      ),
    ),
  );
}

class SplitscreenGame extends FlameGame with KeyboardEvents {
  late TankPlayer player1;
  late TankPlayer player2;
  late CameraComponent cam1;
  late CameraComponent cam2;

  @override
  Color backgroundColor() => const Color(0xFF04060C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Standardkamera entfernen fuer geteilten Bildschirm
    camera.removeFromParent();

    // Welt-Arena mit Gitternetz und Pfeilern fuellen
    world.add(ArenaBackground());
    for (int i = 0; i < 6; i++) {
      world.add(
        ObstaclePillar(
          position: Vector2(
            -300.0 + (i % 3) * 300.0,
            -200.0 + (i ~/ 3) * 400.0,
          ),
        ),
      );
    }

    // Spieler 1 (Blau, WASD)
    player1 = TankPlayer(
      startPos: Vector2(-200, 0),
      bodyColor: const Color(0xFF00E5FF),
      upKey: LogicalKeyboardKey.keyW,
      downKey: LogicalKeyboardKey.keyS,
      leftKey: LogicalKeyboardKey.keyA,
      rightKey: LogicalKeyboardKey.keyD,
    );

    // Spieler 2 (Orange, Pfeiltasten)
    player2 = TankPlayer(
      startPos: Vector2(200, 0),
      bodyColor: const Color(0xFFFF9100),
      upKey: LogicalKeyboardKey.arrowUp,
      downKey: LogicalKeyboardKey.arrowDown,
      leftKey: LogicalKeyboardKey.arrowLeft,
      rightKey: LogicalKeyboardKey.arrowRight,
    );

    world.addAll([player1, player2]);

    final halfW = size.x / 2;
    // Linke Kamera fuer Spieler 1
    cam1 = CameraComponent(
      world: world,
      viewport: FixedSizeViewport(halfW - 2, size.y)
        ..position = Vector2(0, 0),
    );
    cam1.follow(player1);

    // Rechte Kamera fuer Spieler 2
    cam2 = CameraComponent(
      world: world,
      viewport: FixedSizeViewport(halfW - 2, size.y)
        ..position = Vector2(halfW + 2, 0),
    );
    cam2.follow(player2);

    addAll([cam1, cam2]);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Trennlinie in der Mitte
    final dividerPaint = Paint()
      ..color = const Color(0xFF00FFCC)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      dividerPaint,
    );

    // Spieler-Label oben
    final p1Label = TextPainter(
      text: const TextSpan(
        text: 'SPIELER 1 (WASD)',
        style: TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p1Label.paint(canvas, const Offset(20, 20));

    final p2Label = TextPainter(
      text: const TextSpan(
        text: 'SPIELER 2 (PFEILTASTEN)',
        style: TextStyle(
          color: Color(0xFFFF9100),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p2Label.paint(canvas, Offset(size.x / 2 + 20, 20));
  }
}

class ArenaBackground extends Component {
  @override
  void render(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF142030)
      ..strokeWidth = 1.0;

    const span = 800.0;
    const step = 60.0;
    for (double x = -span; x <= span; x += step) {
      canvas.drawLine(Offset(x, -span), Offset(x, span), linePaint);
    }
    for (double y = -span; y <= span; y += step) {
      canvas.drawLine(Offset(-span, y), Offset(span, y), linePaint);
    }
  }
}

class ObstaclePillar extends PositionComponent {
  ObstaclePillar({required Vector2 position})
      : super(
          position: position,
          size: Vector2(40, 40),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF1A2A40)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(const Rect.fromLTWH(-20, -20, 40, 40), paint);
    canvas.drawRect(const Rect.fromLTWH(-20, -20, 40, 40), border);
  }
}

class TankPlayer extends PositionComponent {
  final Color bodyColor;
  final LogicalKeyboardKey upKey;
  final LogicalKeyboardKey downKey;
  final LogicalKeyboardKey leftKey;
  final LogicalKeyboardKey rightKey;

  double angleHeading = 0.0;
  double speed = 0.0;

  TankPlayer({
    required Vector2 startPos,
    required this.bodyColor,
    required this.upKey,
    required this.downKey,
    required this.leftKey,
    required this.rightKey,
  }) : super(
          position: startPos,
          size: Vector2(36, 36),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    if (keys.contains(leftKey)) angleHeading -= 3.0 * dt;
    if (keys.contains(rightKey)) angleHeading += 3.0 * dt;

    if (keys.contains(upKey)) {
      speed = (speed + 400.0 * dt).clamp(0.0, 220.0);
    } else if (keys.contains(downKey)) {
      speed = (speed - 300.0 * dt).clamp(-120.0, 220.0);
    } else {
      if (speed > 0) speed = max(0.0, speed - 250.0 * dt);
      if (speed < 0) speed = min(0.0, speed + 250.0 * dt);
    }

    position.x += cos(angleHeading) * speed * dt;
    position.y += sin(angleHeading) * speed * dt;

    position.x = position.x.clamp(-750.0, 750.0);
    position.y = position.y.clamp(-750.0, 750.0);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(angleHeading);

    final fillPaint = Paint()..color = bodyColor;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(16, 0)
      ..lineTo(-12, -12)
      ..lineTo(-6, 0)
      ..lineTo(-12, 12)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }
}
