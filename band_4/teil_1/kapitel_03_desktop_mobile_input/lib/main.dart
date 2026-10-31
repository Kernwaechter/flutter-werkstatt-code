import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: DualInputGame.new,
    ),
  );
}

/// Steuerbarer Spieler-Schlaeger mit
/// Keyboard- und Touch-Unterstuetzung
class SteuertesPaddle extends PositionComponent {
  final Color farbe;
  double bewegungsRichtung = 0.0;
  static const double geschwindigkeit = 340.0;
  late final Paint _pinsel;

  SteuertesPaddle({
    required Vector2 position,
    required Vector2 size,
    required this.farbe,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pinsel = Paint()
      ..color = farbe
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Bewegung anwenden
    position.y += bewegungsRichtung * geschwindigkeit * dt;

    // Grenzen pruefen (im Spielfeld halten)
    final halbeHoehe = size.y / 2;
    final parentGame = findGame();
    if (parentGame != null) {
      if (position.y - halbeHoehe < 0) {
        position.y = halbeHoehe;
      } else if (position.y + halbeHoehe > parentGame.size.y) {
        position.y = parentGame.size.y - halbeHoehe;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
      _pinsel,
    );
  }
}

/// Ball mit Rueckprall-Logik
class RetroBall extends PositionComponent {
  Vector2 geschwindigkeit;
  final double radius;
  late final Paint _pinsel;

  RetroBall({
    required Vector2 position,
    required this.radius,
    required this.geschwindigkeit,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pinsel = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += geschwindigkeit * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(radius, radius), radius, _pinsel);
  }
}

/// Spiel mit Tastatur (Desktop) und virtuellem Joystick (Mobile)
class DualInputGame extends FlameGame
    with KeyboardEvents, DragCallbacks, TapCallbacks {
  late final SteuertesPaddle spieler;
  late final SteuertesPaddle gegner;
  late final RetroBall ball;
  late final JoystickComponent joystick;

  // Aktive Tastendruecke
  final Set<LogicalKeyboardKey> _gedrueckteTasten = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final mitteY = size.y / 2;

    spieler = SteuertesPaddle(
      position: Vector2(30.0, mitteY),
      size: Vector2(18.0, 90.0),
      farbe: const Color(0xFF00FF66),
    );

    gegner = SteuertesPaddle(
      position: Vector2(size.x - 30.0, mitteY),
      size: Vector2(18.0, 90.0),
      farbe: const Color(0xFFFF0055),
    );

    ball = RetroBall(
      position: Vector2(size.x / 2, mitteY),
      radius: 10.0,
      geschwindigkeit: Vector2(240.0, 160.0),
    );

    // Virtueller Joystick fuer Mobile/Touchscreen
    final knaufFarbe = const Color(0xFF00FF66).withValues(alpha: 0.6);
    final basisFarbe =
        const Color(0xFFFFFFFF).withValues(alpha: 0.15);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 22.0,
        paint: Paint()..color = knaufFarbe,
      ),
      background: CircleComponent(
        radius: 50.0,
        paint: Paint()..color = basisFarbe,
      ),
      margin: const EdgeInsets.only(left: 36.0, bottom: 36.0),
    );

    await add(spieler);
    await add(gegner);
    await add(ball);
    await add(joystick);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _gedrueckteTasten.clear();
    _gedrueckteTasten.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Eingaben auswerten (Tastatur Desktop)
    double richtung = 0.0;
    if (_gedrueckteTasten.contains(LogicalKeyboardKey.keyW) ||
        _gedrueckteTasten.contains(LogicalKeyboardKey.arrowUp)) {
      richtung -= 1.0;
    }
    if (_gedrueckteTasten.contains(LogicalKeyboardKey.keyS) ||
        _gedrueckteTasten.contains(LogicalKeyboardKey.arrowDown)) {
      richtung += 1.0;
    }

    // 2. Eingaben auswerten (Virtueller Joystick Mobile)
    if (joystick.direction != JoystickDirection.idle) {
      richtung = joystick.relativeDelta.y;
    }

    spieler.bewegungsRichtung = richtung;

    // 3. Gegner-KI: Folgt dem Ball
    final diffY = ball.position.y - gegner.position.y;
    if (diffY.abs() > 6.0) {
      gegner.bewegungsRichtung = diffY > 0 ? 0.8 : -0.8;
    } else {
      gegner.bewegungsRichtung = 0.0;
    }

    // 4. Ball-Kollision mit Rändern
    if (ball.position.y - ball.radius <= 0) {
      ball.position.y = ball.radius;
      ball.geschwindigkeit.y = -ball.geschwindigkeit.y;
    } else if (ball.position.y + ball.radius >= size.y) {
      ball.position.y = size.y - ball.radius;
      ball.geschwindigkeit.y = -ball.geschwindigkeit.y;
    }

    // 5. Paddle-Kollisionen
    _pruefeKollision(spieler, isLinks: true);
    _pruefeKollision(gegner, isLinks: false);

    // 6. Spielfeld-Aus
    if (ball.position.x < 0 || ball.position.x > size.x) {
      ball.position = Vector2(size.x / 2, size.y / 2);
      ball.geschwindigkeit.x = -ball.geschwindigkeit.x;
    }
  }

  void _pruefeKollision(
    SteuertesPaddle paddle, {
    required bool isLinks,
  }) {
    final ballRect = Rect.fromCircle(
      center: Offset(ball.position.x, ball.position.y),
      radius: ball.radius,
    );
    final pRect = Rect.fromCenter(
      center: Offset(paddle.position.x, paddle.position.y),
      width: paddle.size.x,
      height: paddle.size.y,
    );

    if (ballRect.overlaps(pRect)) {
      final abstand = (paddle.size.x / 2) + ball.radius;
      if (isLinks && ball.geschwindigkeit.x < 0) {
        ball.position.x = paddle.position.x + abstand;
        ball.geschwindigkeit.x = -ball.geschwindigkeit.x * 1.05;
      } else if (!isLinks && ball.geschwindigkeit.x > 0) {
        ball.position.x = paddle.position.x - abstand;
        ball.geschwindigkeit.x = -ball.geschwindigkeit.x * 1.05;
      }
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0E14);
}
