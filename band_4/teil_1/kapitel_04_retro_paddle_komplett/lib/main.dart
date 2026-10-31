import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const RetroPaddleApp());
}

/// Einstiegs-Widget mit Flutter-Overlays fuer
/// HUD, Pause und Game-Over
class RetroPaddleApp extends StatelessWidget {
  const RetroPaddleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget<RetroPaddleGame>.controlled(
          gameFactory: RetroPaddleGame.new,
          overlayBuilderMap: {
            'HUD': (context, game) => HudOverlay(game: game),
            'PauseMenu': (context, game) => PauseOverlay(game: game),
            'GameOver': (context, game) =>
                GameOverOverlay(game: game),
          },
          initialActiveOverlays: const ['HUD'],
        ),
      ),
    );
  }
}

/// HUD-Overlay: Zeigt Spielstand und Pause-Taste
class HudOverlay extends StatelessWidget {
  final RetroPaddleGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Punktestand
            ValueListenableBuilder<String>(
              valueListenable: game.scoreNotifier,
              builder: (context, scoreText, _) {
                return Text(
                  scoreText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FF66),
                    letterSpacing: 4.0,
                  ),
                );
              },
            ),
            // Pause-Knopf
            IconButton(
              icon: const Icon(Icons.pause, size: 28.0),
              color: Colors.white70,
              onPressed: game.pausiereSpiel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pause-Menue
class PauseOverlay extends StatelessWidget {
  final RetroPaddleGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280.0,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF101418).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFF00FF66),
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SPIEL PAUSIERT',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF66),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: game.fortsetzen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF66),
                foregroundColor: Colors.black,
              ),
              child: const Text('WEITERSPIELEN'),
            ),
            const SizedBox(height: 10.0),
            TextButton(
              onPressed: game.neustart,
              child: const Text(
                'NEUSTART',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game-Over-Overlay
class GameOverOverlay extends StatelessWidget {
  final RetroPaddleGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final sieg = game.spielerScore >= game.zielPunkte;
    return Center(
      child: Container(
        width: 300.0,
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(
          color: const Color(0xFF101418).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: sieg
                ? const Color(0xFF00FF66)
                : const Color(0xFFFF0055),
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sieg ? 'SIEG!' : 'NIEDERLAGE!',
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: sieg
                    ? const Color(0xFF00FF66)
                    : const Color(0xFFFF0055),
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Endstand: ${game.scoreNotifier.value}',
              style: const TextStyle(
                fontSize: 18.0,
                fontFamily: 'monospace',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: game.neustart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF66),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
              child: const Text('NOCHMAL SPIELEN'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Schlaeger
class Paddle extends PositionComponent {
  final Color farbe;
  double bewegungsRichtung = 0.0;
  static const double geschwindigkeit = 360.0;
  late final Paint _pinsel;

  Paddle({
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
    position.y += bewegungsRichtung * geschwindigkeit * dt;

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

/// Ball
class Ball extends PositionComponent {
  Vector2 geschwindigkeit;
  final double radius;
  late final Paint _pinsel;

  Ball({
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

/// Das fertige Retro-Paddle-Spiel
class RetroPaddleGame extends FlameGame
    with KeyboardEvents, DragCallbacks, TapCallbacks {
  late final Paddle spieler;
  late final Paddle gegner;
  late final Ball ball;
  late final JoystickComponent joystick;

  // Punktestand & Notifier
  int spielerScore = 0;
  int gegnerScore = 0;
  final int zielPunkte = 5;
  final ValueNotifier<String> scoreNotifier =
      ValueNotifier<String>('0 : 0');

  bool isPausiert = false;
  bool isGameOver = false;

  final Set<LogicalKeyboardKey> _gedrueckteTasten = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final mitteY = size.y / 2;

    spieler = Paddle(
      position: Vector2(32.0, mitteY),
      size: Vector2(18.0, 96.0),
      farbe: const Color(0xFF00FF66),
    );

    gegner = Paddle(
      position: Vector2(size.x - 32.0, mitteY),
      size: Vector2(18.0, 96.0),
      farbe: const Color(0xFFFF0055),
    );

    ball = Ball(
      position: Vector2(size.x / 2, mitteY),
      radius: 10.0,
      geschwindigkeit: Vector2(260.0, 160.0),
    );

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20.0,
        paint: Paint()
          ..color = const Color(0xFF00FF66).withValues(alpha: 0.6),
      ),
      background: CircleComponent(
        radius: 46.0,
        paint: Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.15),
      ),
      margin: const EdgeInsets.only(left: 32.0, bottom: 32.0),
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

    if (keysPressed.contains(LogicalKeyboardKey.escape)) {
      if (!isGameOver) {
        if (isPausiert) {
          fortsetzen();
        } else {
          pausiereSpiel();
        }
      }
    }
    return KeyEventResult.handled;
  }

  void pausiereSpiel() {
    if (isGameOver) return;
    isPausiert = true;
    pauseEngine();
    overlays.add('PauseMenu');
  }

  void fortsetzen() {
    if (isGameOver) return;
    isPausiert = false;
    overlays.remove('PauseMenu');
    resumeEngine();
  }

  void neustart() {
    spielerScore = 0;
    gegnerScore = 0;
    scoreNotifier.value = '0 : 0';
    isGameOver = false;
    isPausiert = false;
    overlays.remove('PauseMenu');
    overlays.remove('GameOver');
    _resetBall(nachRechts: true);
    resumeEngine();
  }

  void _resetBall({required bool nachRechts}) {
    ball.position = Vector2(size.x / 2, size.y / 2);
    final zufallWinkel = (math.Random().nextDouble() - 0.5) * 0.8;
    final vorzeichen = nachRechts ? 1.0 : -1.0;
    ball.geschwindigkeit = Vector2(
      vorzeichen * 260.0,
      zufallWinkel * 260.0,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPausiert || isGameOver) return;

    // 1. Eingaben
    double richtung = 0.0;
    if (_gedrueckteTasten.contains(LogicalKeyboardKey.keyW) ||
        _gedrueckteTasten.contains(LogicalKeyboardKey.arrowUp)) {
      richtung -= 1.0;
    }
    if (_gedrueckteTasten.contains(LogicalKeyboardKey.keyS) ||
        _gedrueckteTasten.contains(LogicalKeyboardKey.arrowDown)) {
      richtung += 1.0;
    }

    if (joystick.direction != JoystickDirection.idle) {
      richtung = joystick.relativeDelta.y;
    }
    spieler.bewegungsRichtung = richtung;

    // 2. Gegner-KI
    final diffY = ball.position.y - gegner.position.y;
    if (diffY.abs() > 6.0) {
      gegner.bewegungsRichtung = diffY > 0 ? 0.82 : -0.82;
    } else {
      gegner.bewegungsRichtung = 0.0;
    }

    // 3. Wand-Kollision
    if (ball.position.y - ball.radius <= 0) {
      ball.position.y = ball.radius;
      ball.geschwindigkeit.y = -ball.geschwindigkeit.y;
    } else if (ball.position.y + ball.radius >= size.y) {
      ball.position.y = size.y - ball.radius;
      ball.geschwindigkeit.y = -ball.geschwindigkeit.y;
    }

    // 4. Paddle-Kollision
    _kollision(spieler, isLinks: true);
    _kollision(gegner, isLinks: false);

    // 5. Punkt-Erzielung
    if (ball.position.x < 0) {
      gegnerScore++;
      scoreNotifier.value = '$spielerScore : $gegnerScore';
      _pruefeEnde();
      _resetBall(nachRechts: true);
    } else if (ball.position.x > size.x) {
      spielerScore++;
      scoreNotifier.value = '$spielerScore : $gegnerScore';
      _pruefeEnde();
      _resetBall(nachRechts: false);
    }
  }

  void _pruefeEnde() {
    if (spielerScore >= zielPunkte || gegnerScore >= zielPunkte) {
      isGameOver = true;
      pauseEngine();
      overlays.add('GameOver');
    }
  }

  void _kollision(Paddle paddle, {required bool isLinks}) {
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
        ball.geschwindigkeit.x = -ball.geschwindigkeit.x * 1.06;
      } else if (!isLinks && ball.geschwindigkeit.x > 0) {
        ball.position.x = paddle.position.x - abstand;
        ball.geschwindigkeit.x = -ball.geschwindigkeit.x * 1.06;
      }
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF080C10);
}
