import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const WerkbankRunnerApp());
}

/// Einstiegs-App mit HUD- und Game-Over-Overlays
class WerkbankRunnerApp extends StatelessWidget {
  const WerkbankRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget<WerkbankRunnerGame>.controlled(
          gameFactory: WerkbankRunnerGame.new,
          overlayBuilderMap: {
            'HUD': (context, game) => RunnerHud(game: game),
            'GameOver': (context, game) => RunnerGameOver(game: game),
          },
          initialActiveOverlays: const ['HUD'],
        ),
      ),
    );
  }
}

/// HUD-Overlay
class RunnerHud extends StatelessWidget {
  final WerkbankRunnerGame game;
  const RunnerHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.meterNotifier,
              builder: (context, meter, _) {
                return Text(
                  '$meter m',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FF66),
                  ),
                );
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.muenzenNotifier,
              builder: (context, muenzen, _) {
                return Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFFFD700),
                      size: 24.0,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '$muenzen',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Game-Over-Overlay
class RunnerGameOver extends StatelessWidget {
  final WerkbankRunnerGame game;
  const RunnerGameOver({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 290.0,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF101418).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFFF0055),
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF0055),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Distanz: ${game.meterNotifier.value} Meter',
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Münzen: ${game.muenzenNotifier.value}',
              style: const TextStyle(
                fontSize: 16.0,
                color: Color(0xFFFFD700),
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
              child: const Text('NOCHMAL LAUFEN'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zustaende des Runners
enum RunnerState { laufen, springen }

/// Spielfigur
class RunnerPlayer
    extends SpriteAnimationGroupComponent<RunnerState> {
  double vertikaleGeschwindigkeit = 0.0;
  static const double gravitaet = 960.0;
  static const double sprungKraft = -420.0;
  late final double bodenY;

  RunnerPlayer({required Vector2 position})
      : super(
          position: position,
          size: Vector2(32, 32) * 2.8,
          anchor: Anchor.bottomCenter,
          current: RunnerState.laufen,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    bodenY = position.y;

    final sheetImage = await Flame.images.load('runner_sheet.png');

    final laufAnimation = SpriteAnimation.fromFrameData(
      sheetImage,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.11,
        textureSize: Vector2(32, 32),
      ),
    );

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
      RunnerState.laufen: laufAnimation,
      RunnerState.springen: sprungAnimation,
    };
  }

  void springen() {
    if (current == RunnerState.laufen) {
      vertikaleGeschwindigkeit = sprungKraft;
      current = RunnerState.springen;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (current == RunnerState.springen) {
      vertikaleGeschwindigkeit += gravitaet * dt;
      position.y += vertikaleGeschwindigkeit * dt;

      if (position.y >= bodenY) {
        position.y = bodenY;
        vertikaleGeschwindigkeit = 0.0;
        current = RunnerState.laufen;
      }
    }
  }
}

/// Hindernis (Fels)
class HindernisComponent extends SpriteComponent {
  static const double tempo = 200.0;

  HindernisComponent({
    required Vector2 position,
    required Sprite sprite,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(32, 32) * 2.2,
          anchor: Anchor.bottomLeft,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= tempo * dt;
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}

/// Goldmuenze
class MuenzenComponent extends SpriteComponent {
  static const double tempo = 200.0;

  MuenzenComponent({
    required Vector2 position,
    required Sprite sprite,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(16, 16) * 2.2,
          anchor: Anchor.center,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= tempo * dt;
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}

/// Das Hauptspiel
class WerkbankRunnerGame extends FlameGame
    with KeyboardEvents, TapCallbacks {
  late final ParallaxComponent parallax;
  late final RunnerPlayer runner;
  late final Sprite felsenSprite;
  late final Sprite muenzenSprite;

  final ValueNotifier<int> meterNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> muenzenNotifier = ValueNotifier<int>(0);

  double _zeitBisSpawn = 1.8;
  double _meterZaehler = 0.0;
  bool isGameOver = false;

  final math.Random _zufall = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Parallax laden
    parallax = await loadParallaxComponent(
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
    await add(parallax);

    // 2. Sprites laden
    final rockImg = await Flame.images.load('rock.png');
    final coinImg = await Flame.images.load('coin.png');
    felsenSprite = Sprite(rockImg);
    muenzenSprite = Sprite(coinImg);

    // 3. Runner hinzufuegen
    final bodenY = size.y - 32.0;
    runner = RunnerPlayer(position: Vector2(80.0, bodenY));
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
      if (!isGameOver) {
        runner.springen();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!isGameOver) {
      runner.springen();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // Distanzzaehler
    _meterZaehler += 20 * dt;
    meterNotifier.value = _meterZaehler.toInt();

    // Spawning von Objekten
    _zeitBisSpawn -= dt;
    if (_zeitBisSpawn <= 0) {
      _zeitBisSpawn = 1.6 + _zufall.nextDouble() * 1.4;
      _erzeugeObjekt();
    }

    // Kollisionspruefungen
    _pruefeKollisionen();
  }

  void _erzeugeObjekt() {
    final bodenY = size.y - 32.0;
    final istMuenze = _zufall.nextBool();

    if (istMuenze) {
      final muenzeY = bodenY - 50.0 - (_zufall.nextDouble() * 40.0);
      add(
        MuenzenComponent(
          position: Vector2(size.x + 20, muenzeY),
          sprite: muenzenSprite,
        ),
      );
    } else {
      add(
        HindernisComponent(
          position: Vector2(size.x + 20, bodenY),
          sprite: felsenSprite,
        ),
      );
    }
  }

  void _pruefeKollisionen() {
    final runnerRect = runner.toRect();

    // 1. Hindernisse pruefen
    final hindernisse = children.whereType<HindernisComponent>();
    for (final hindernis in hindernisse) {
      // Verkleinerte Hitbox fuer faire Kollision
      final hRect = hindernis.toRect().deflate(10.0);
      if (runnerRect.overlaps(hRect)) {
        isGameOver = true;
        pauseEngine();
        overlays.add('GameOver');
        return;
      }
    }

    // 2. Muenzen einsammeln
    for (final muenze in children.whereType<MuenzenComponent>()) {
      if (runnerRect.overlaps(muenze.toRect())) {
        muenze.removeFromParent();
        muenzenNotifier.value++;
      }
    }
  }

  void neustart() {
    // Alle Hindernisse und Muenzen loeschen
    removeAll(children.whereType<HindernisComponent>());
    removeAll(children.whereType<MuenzenComponent>());

    meterNotifier.value = 0;
    muenzenNotifier.value = 0;
    _meterZaehler = 0.0;
    _zeitBisSpawn = 1.8;
    isGameOver = false;

    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  Color backgroundColor() => const Color(0xFF101824);
}
