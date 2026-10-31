import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: AnimationDemoGame.new,
    ),
  );
}

/// Zustaende der Spielfigur
enum RunnerZustand { laufen, springen }

/// Animierte Spielfigur mit Sprung-Physik
class AnimierterRunner
    extends SpriteAnimationGroupComponent<RunnerZustand>
    with HasGameReference<AnimationDemoGame> {
  // Sprung- und Gravitationswerte
  double vertikaleGeschwindigkeit = 0.0;
  static const double gravitaet = 980.0;
  static const double sprungKraft = -440.0;
  late final double bodenY;

  AnimierterRunner({required Vector2 position})
      : super(
          position: position,
          size: Vector2(32, 32) * 3.5,
          anchor: Anchor.bottomCenter,
          current: RunnerZustand.laufen,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    bodenY = position.y;

    final sheetImage = await Flame.images.load('runner_sheet.png');

    // 1. Lauf-Animation: 4 Frames à 32x32, 120ms pro Frame
    final laufAnimation = SpriteAnimation.fromFrameData(
      sheetImage,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.12,
        textureSize: Vector2(32, 32),
      ),
    );

    // 2. Sprung-Pose: Frame 2 (abgewinkeltes Bein) als Standbild
    final sprungAnimation = SpriteAnimation.fromFrameData(
      sheetImage,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(32, 32),
        texturePosition: Vector2(32, 0),
      ),
    );

    animations = {
      RunnerZustand.laufen: laufAnimation,
      RunnerZustand.springen: sprungAnimation,
    };
  }

  void springen() {
    // Nur springen, wenn die Figur auf dem Boden steht
    if (current == RunnerZustand.laufen) {
      vertikaleGeschwindigkeit = sprungKraft;
      current = RunnerZustand.springen;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (current == RunnerZustand.springen) {
      // Gravitation auf Geschwindigkeit und Position anwenden
      vertikaleGeschwindigkeit += gravitaet * dt;
      position.y += vertikaleGeschwindigkeit * dt;

      // Landung auf dem Boden pruefen
      if (position.y >= bodenY) {
        position.y = bodenY;
        vertikaleGeschwindigkeit = 0.0;
        current = RunnerZustand.laufen;
      }
    }
  }
}

/// Spiel zur Demonstration von Frame-Animationen und Spruengen
class AnimationDemoGame extends FlameGame
    with KeyboardEvents, TapCallbacks {
  late final AnimierterRunner runner;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    runner = AnimierterRunner(
      position: Vector2(size.x / 2, size.y - 80.0),
    );

    await add(runner);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      runner.springen();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    runner.springen();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Bodenlinie zeichnen
    final bodenPinsel = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 4.0;
    canvas.drawLine(
      Offset(0, size.y - 80.0),
      Offset(size.x, size.y - 80.0),
      bodenPinsel,
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF0E1520);
}
