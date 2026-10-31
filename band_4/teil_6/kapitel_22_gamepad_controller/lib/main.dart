import 'dart:math';
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
        backgroundColor: Color(0xFF070A12),
        body: GameWidget.controlled(gameFactory: GamepadLabGame.new),
      ),
    ),
  );
}

class GamepadLabGame extends FlameGame with KeyboardEvents {
  late ControllableVehicle vehicle;
  String lastGamepadInput = 'Kein Controller-Signal';

  @override
  Color backgroundColor() => const Color(0xFF060810);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    vehicle = ControllableVehicle(position: size / 2);
    add(vehicle);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Gamepad-Knoepfe pruefen
    if (keysPressed.contains(LogicalKeyboardKey.gameButtonA)) {
      lastGamepadInput = 'Button A gedrueckt (Feuer)';
    } else if (keysPressed.contains(LogicalKeyboardKey.gameButtonB)) {
      lastGamepadInput = 'Button B gedrueckt (Boost)';
    } else if (keysPressed.contains(LogicalKeyboardKey.gameButtonX)) {
      lastGamepadInput = 'D-Pad Oben';
    } else {
      final count = keysPressed.length;
      lastGamepadInput = 'Tastatur / Pad aktiv: $count';
    }
    return KeyEventResult.ignored;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Gamepad & Desktop-Controller Diagnoselabor\n'
            'Signal: $lastGamepadInput\n'
            'Steuerung: [WASD / D-Pad] Fahren\n'
            '[Leertaste / Button A] Turbo',
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

class ControllableVehicle extends PositionComponent
    with HasGameReference<GamepadLabGame> {
  ControllableVehicle({required Vector2 position})
      : super(
          position: position,
          size: Vector2(48, 48),
          anchor: Anchor.center,
        );

  double heading = 0.0;
  double currentSpeed = 0.0;
  final double maxSpeed = 220.0;
  final double turnSpeed = 3.2;

  @override
  void update(double dt) {
    super.update(dt);

    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    // Lenkung (A/D oder Pfeile oder Gamepad D-Pad)
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft) ||
        keys.contains(LogicalKeyboardKey.gameButtonLeft1)) {
      heading -= turnSpeed * dt;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight) ||
        keys.contains(LogicalKeyboardKey.gameButtonRight1)) {
      heading += turnSpeed * dt;
    }

    // Beschleunigung
    bool forward = keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp) ||
        keys.contains(LogicalKeyboardKey.gameButtonX);

    bool turbo = keys.contains(LogicalKeyboardKey.space) ||
        keys.contains(LogicalKeyboardKey.gameButtonA) ||
        keys.contains(LogicalKeyboardKey.gameButtonB);

    final targetMax = turbo ? maxSpeed * 1.5 : maxSpeed;

    if (forward) {
      final nextSpd = currentSpeed + 350.0 * dt;
      currentSpeed = nextSpd.clamp(0.0, targetMax);
    } else {
      // Reibungsbremse
      currentSpeed = max(0.0, currentSpeed - 200.0 * dt);
    }

    // Vorwaertsbewegung
    position.x += cos(heading) * currentSpeed * dt;
    position.y += sin(heading) * currentSpeed * dt;

    // Bildschirm-Wrapping
    if (position.x < 0) position.x = game.size.x;
    if (position.x > game.size.x) position.x = 0;
    if (position.y < 0) position.y = game.size.y;
    if (position.y > game.size.y) position.y = 0;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(heading);

    final fillPaint = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(20, 0)
      ..lineTo(-14, -14)
      ..lineTo(-6, 0)
      ..lineTo(-14, 14)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }
}
