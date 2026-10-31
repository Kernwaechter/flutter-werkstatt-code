import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: ParallaxDemoGame.new,
    ),
  );
}

/// Demonstration von mehrschichtigem Parallax-Scrolling
class ParallaxDemoGame extends FlameGame with TapCallbacks {
  late final ParallaxComponent parallaxKomponente;
  bool isTurbo = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 3 Schichten mit unterschiedlichen
    // Geschwindigkeits-Multiplikatoren
    parallaxKomponente = await loadParallaxComponent(
      [
        ParallaxImageData('parallax_mountains.png'),
        ParallaxImageData('parallax_trees.png'),
        ParallaxImageData('parallax_ground.png'),
      ],
      baseVelocity: Vector2(120, 0),
      velocityMultiplierDelta: Vector2(1.8, 0),
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.width,
      alignment: Alignment.bottomCenter,
    );

    await add(parallaxKomponente);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Klick oder Tap schaltet Turbo ein/aus
    isTurbo = !isTurbo;
    final tempo = isTurbo ? 280.0 : 120.0;
    parallaxKomponente.parallax?.baseVelocity = Vector2(tempo, 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Infotext
    final textPinsel = TextPaint(
      style: const TextStyle(
        color: Color(0xFF00FF66),
        fontSize: 14.0,
        fontFamily: 'monospace',
      ),
    );

    final status = isTurbo ? 'TURBO (280 px/s)' : 'NORMAL (120 px/s)';
    textPinsel.render(
      canvas,
      'Parallax: $status | Tippe fuer Turbo',
      Vector2(16, 24),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF101824);
}
