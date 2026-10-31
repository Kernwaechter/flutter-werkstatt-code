import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: SpriteDemoGame.new,
    ),
  );
}

/// Demonstration von Sprites, Ausschnitten und Pixel-Filterung
class SpriteDemoGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Textur-Atlas (Runner-Sheet) in den Speicher laden
    final sheetImage = await Flame.images.load('runner_sheet.png');
    final coinImage = await Flame.images.load('coin.png');
    final rockImage = await Flame.images.load('rock.png');

    // 2. Einzelsprite aus dem Atlas ausschneiden (Frame 1: Standpose)
    final runnerSpriteStand = Sprite(
      sheetImage,
      srcPosition: Vector2(0, 0),
      srcSize: Vector2(32, 32),
    );

    // Frame 3: Laufpose mit gestrecktem Bein
    final runnerSpriteLauf = Sprite(
      sheetImage,
      srcPosition: Vector2(64, 0),
      srcSize: Vector2(32, 32),
    );

    // 3. Komponenten fuer die Anzeige erzeugen (4x vergroessert)
    const scaleFactor = 4.0;

    final standFigur = SpriteComponent(
      sprite: runnerSpriteStand,
      position: Vector2(60, 100),
      size: Vector2(32, 32) * scaleFactor,
      paint: Paint()..filterQuality = FilterQuality.none,
    );

    final laufFigur = SpriteComponent(
      sprite: runnerSpriteLauf,
      position: Vector2(220, 100),
      size: Vector2(32, 32) * scaleFactor,
      paint: Paint()..filterQuality = FilterQuality.none,
    );

    final hindernis = SpriteComponent(
      sprite: Sprite(rockImage),
      position: Vector2(380, 100),
      size: Vector2(32, 32) * scaleFactor,
      paint: Paint()..filterQuality = FilterQuality.none,
    );

    final muenze = SpriteComponent(
      sprite: Sprite(coinImage),
      position: Vector2(540, 130),
      size: Vector2(16, 16) * scaleFactor,
      paint: Paint()..filterQuality = FilterQuality.none,
    );

    await add(standFigur);
    await add(laufFigur);
    await add(hindernis);
    await add(muenze);
  }

  @override
  Color backgroundColor() => const Color(0xFF141A22);
}
