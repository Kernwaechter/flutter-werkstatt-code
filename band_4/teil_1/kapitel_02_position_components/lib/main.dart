import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: RetroFcsGame.new,
    ),
  );
}

/// Schlaeger-Komponente im Flame Component System
class PaddleComponent extends PositionComponent {
  final Color farbe;
  late final Paint _pinsel;

  PaddleComponent({
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
  void render(Canvas canvas) {
    super.render(canvas);
    // Das Rechteck wird relativ zum Ankerpunkt gezeichnet
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
      _pinsel,
    );
  }
}

/// Ball-Komponente mit eigener Geschwindigkeit und Logik
class BallComponent extends PositionComponent {
  Vector2 geschwindigkeit;
  final double radius;
  late final Paint _pinsel;

  BallComponent({
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
    // Bewegung anwenden
    position += geschwindigkeit * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(radius, radius), radius, _pinsel);
  }
}

/// Das Hauptspiel: Verwaltet alle Komponenten im FCS-Baum
class RetroFcsGame extends FlameGame {
  late final PaddleComponent spielerPaddle;
  late final PaddleComponent gegnerPaddle;
  late final BallComponent ball;

  static const double paddleBreite = 18.0;
  static const double paddleHoehe = 90.0;
  static const double ballRadius = 10.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final mitteX = size.x / 2;
    final mitteY = size.y / 2;

    // Spieler-Schlaeger links
    spielerPaddle = PaddleComponent(
      position: Vector2(30.0, mitteY),
      size: Vector2(paddleBreite, paddleHoehe),
      farbe: const Color(0xFF00FF66),
    );

    // Gegner-Schlaeger rechts
    gegnerPaddle = PaddleComponent(
      position: Vector2(size.x - 30.0, mitteY),
      size: Vector2(paddleBreite, paddleHoehe),
      farbe: const Color(0xFFFF0055),
    );

    // Ball in der Mitte starten
    ball = BallComponent(
      position: Vector2(mitteX, mitteY),
      radius: ballRadius,
      geschwindigkeit: Vector2(260.0, 180.0),
    );

    // Komponenten dem Spielbaum hinzufuegen
    await add(spielerPaddle);
    await add(gegnerPaddle);
    await add(ball);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Einfache KI fuer den rechten Schlaeger: folgt dem Ball
    final zielY = ball.position.y;
    final abstandY = zielY - gegnerPaddle.position.y;
    const kiGeschwindigkeit = 190.0;

    if (abstandY.abs() > 4.0) {
      final richtung = abstandY > 0 ? 1.0 : -1.0;
      gegnerPaddle.position.y += richtung * kiGeschwindigkeit * dt;
    }

    // Schlaeger im Spielfeld halten
    _klemmePaddle(spielerPaddle);
    _klemmePaddle(gegnerPaddle);

    // Ball-Kollision mit oberem und unterem Rand
    if (ball.position.y - ballRadius <= 0) {
      ball.position.y = ballRadius;
      ball.geschwindigkeit.y = -ball.geschwindigkeit.y;
    } else if (ball.position.y + ballRadius >= size.y) {
      ball.position.y = size.y - ballRadius;
      ball.geschwindigkeit.y = -ball.geschwindigkeit.y;
    }

    // Ball-Kollision mit den Schlaegern
    _pruefePaddleKollision(spielerPaddle, isLinks: true);
    _pruefePaddleKollision(gegnerPaddle, isLinks: false);

    // Ball aus dem Spielfeld (Neustart in der Mitte)
    if (ball.position.x < 0 || ball.position.x > size.x) {
      ball.position = Vector2(size.x / 2, size.y / 2);
      ball.geschwindigkeit.x = -ball.geschwindigkeit.x;
    }
  }

  void _klemmePaddle(PaddleComponent paddle) {
    final halbeHoehe = paddle.size.y / 2;
    if (paddle.position.y - halbeHoehe < 0) {
      paddle.position.y = halbeHoehe;
    } else if (paddle.position.y + halbeHoehe > size.y) {
      paddle.position.y = size.y - halbeHoehe;
    }
  }

  void _pruefePaddleKollision(
    PaddleComponent paddle, {
    required bool isLinks,
  }) {
    final ballRect = Rect.fromCircle(
      center: Offset(ball.position.x, ball.position.y),
      radius: ball.radius,
    );
    final paddleRect = Rect.fromCenter(
      center: Offset(paddle.position.x, paddle.position.y),
      width: paddle.size.x,
      height: paddle.size.y,
    );

    if (ballRect.overlaps(paddleRect)) {
      final halbeBreite = paddle.size.x / 2;
      final offset = halbeBreite + ball.radius;
      if (isLinks && ball.geschwindigkeit.x < 0) {
        ball.position.x = paddle.position.x + offset;
        ball.geschwindigkeit.x = -ball.geschwindigkeit.x * 1.05;
      } else if (!isLinks && ball.geschwindigkeit.x > 0) {
        ball.position.x = paddle.position.x - offset;
        ball.geschwindigkeit.x = -ball.geschwindigkeit.x * 1.05;
      }
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF0D1117);
}
