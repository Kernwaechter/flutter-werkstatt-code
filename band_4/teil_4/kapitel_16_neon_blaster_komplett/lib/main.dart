import 'dart:math';
import 'dart:ui' hide TextStyle;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF06070E),
        body: GameWidget.controlled(
          gameFactory: NeonBlasterGame.new,
          overlayBuilderMap: {
            'GameOver': (context, NeonBlasterGame game) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101220)
                        .withValues(alpha: 0.92),
                    border: Border.all(
                      color: const Color(0xFFFF0055),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 32,
                          color: Color(0xFFFF0055),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Punkte: ${game.score}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: game.restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFCC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          'NEUER VERSUCH',
                          style:
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          },
        ),
      ),
    ),
  );
}

class NeonBlasterGame extends FlameGame
    with
        HasCollisionDetection,
        KeyboardEvents,
        DragCallbacks,
        TapCallbacks {
  final Random rng = Random();
  late PlayerShip player;
  FragmentShader? crtShader;
  double elapsed = 0.0;
  int score = 0;
  int lives = 3;
  bool isGameOver = false;
  double spawnTimer = 0.0;
  bool crtEnabled = true;

  @override
  Color backgroundColor() => const Color(0xFF04060C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Sound-Effekte vorab laden
    await FlameAudio.audioCache.loadAll([
      'laser.wav',
      'explosion.wav',
      'powerup.wav',
      'chiptune_loop.wav',
    ]);
    FlameAudio.bgm.play('chiptune_loop.wav', volume: 0.4);

    // CRT-Shader initialisieren
    final program = await FragmentProgram.fromAsset(
      'shaders/crt.frag',
    );
    crtShader = program.fragmentShader();

    // Spieler-Raumschiff platzieren
    player = PlayerShip();
    add(player);
  }

  void playSfx(String name) {
    FlameAudio.play(name, volume: 0.7);
  }

  void restartGame() {
    score = 0;
    lives = 3;
    isGameOver = false;
    overlays.remove('GameOver');

    // Entferne alte Gegner und Projektile
    for (final e in children.whereType<EnemyDrone>()) {
      e.removeFromParent();
    }
    for (final b in children.whereType<LaserBolt>()) {
      b.removeFromParent();
    }

    player.position = Vector2(size.x / 2, size.y - 80);
    resumeEngine();
  }

  void triggerGameOver() {
    isGameOver = true;
    overlays.add('GameOver');
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;
    elapsed += dt;
    spawnTimer += dt;

    if (spawnTimer > 1.2) {
      spawnTimer = 0.0;
      final spawnX = 40.0 + rng.nextDouble() * (size.x - 80.0);
      add(EnemyDrone(position: Vector2(spawnX, -30)));
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isGameOver) return;
    final nextX = player.position.x + event.localDelta.x;
    player.position.x = nextX.clamp(
      30.0,
      size.x - 30.0,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    player.shoot();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (isGameOver) return KeyEventResult.ignored;

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space) {
      player.shoot();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // CRT-Scanlines zeichnen
    final shader = crtShader;
    if (shader != null && crtEnabled) {
      shader.setFloat(0, size.x);
      shader.setFloat(1, size.y);
      shader.setFloat(2, elapsed);
      shader.setFloat(3, 1.0);

      final p = Paint()..shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), p);
    }

    // HUD oben links
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SCORE: $score   LIVES: $lives',
        style: const TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }
}

class PlayerShip extends PositionComponent
    with HasGameReference<NeonBlasterGame> {
  PlayerShip()
      : super(
          size: Vector2(40, 40),
          anchor: Anchor.center,
        );

  final double moveSpeed = 350.0;
  double _thrusterTimer = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x / 2, game.size.y - 80);
    add(CircleHitbox(radius: 16, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _thrusterTimer += dt;

    // Tastatursteuerung Desktop
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      position.x -= moveSpeed * dt;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      position.x += moveSpeed * dt;
    }

    position.x = position.x.clamp(20.0, game.size.x - 20.0);

    // Triebwerkspartikel
    if (_thrusterTimer > 0.05) {
      _thrusterTimer = 0.0;
      _spawnThruster();
    }
  }

  void _spawnThruster() {
    game.add(
      ParticleSystemComponent(
        particle: AcceleratedParticle(
          position: Vector2(position.x, position.y + 18),
          speed: Vector2(
            (game.rng.nextDouble() - 0.5) * 30.0,
            120.0 + game.rng.nextDouble() * 60.0,
          ),
          child: ComputedParticle(
            lifespan: 0.25,
            renderer: (canvas, particle) {
              final p = particle.progress;
              final paint = Paint()
                ..color = Color.lerp(
                  const Color(0xFF00FFFF),
                  const Color(0xFFFF0055),
                  p,
                )!.withValues(alpha: 1.0 - p);
              canvas.drawCircle(Offset.zero, (1.0 - p) * 3.5, paint);
            },
          ),
        ),
      ),
    );
  }

  void shoot() {
    game.playSfx('laser.wav');
    // Dual Blaster: Zwei Laserstrahlen links und rechts
    final pY = position.y - 15;
    game.add(LaserBolt(position: Vector2(position.x - 12, pY)));
    game.add(LaserBolt(position: Vector2(position.x + 12, pY)));
  }

  @override
  void render(Canvas canvas) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x / 2, size.y - 8)
      ..lineTo(0, size.y)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, bodyPaint);
  }
}

class LaserBolt extends PositionComponent
    with CollisionCallbacks, HasGameReference<NeonBlasterGame> {
  LaserBolt({required Vector2 position})
      : super(
          position: position,
          size: Vector2(4, 16),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 600.0 * dt;
    if (position.y < -20) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(2),
      ),
      paint,
    );
  }
}

class EnemyDrone extends PositionComponent
    with CollisionCallbacks, HasGameReference<NeonBlasterGame> {
  EnemyDrone({required Vector2 position})
      : super(
          position: position,
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  final double speed = 140.0;
  double wobble = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 14, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    wobble += dt * 4.0;
    position.y += speed * dt;
    position.x += sin(wobble) * 40.0 * dt;

    if (position.y > game.size.y + 40) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is LaserBolt) {
      other.removeFromParent();
      _explode();
      game.score += 100;
      removeFromParent();
    } else if (other is PlayerShip) {
      _explode();
      game.lives--;
      if (game.lives <= 0) {
        game.triggerGameOver();
      }
      removeFromParent();
    }
  }

  void _explode() {
    game.playSfx('explosion.wav');
    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 24,
          lifespan: 0.6,
          generator: (i) {
            final angle = game.rng.nextDouble() * 2 * pi;
            final vel = 40.0 + game.rng.nextDouble() * 180.0;
            return AcceleratedParticle(
              position: position.clone(),
              speed: Vector2(cos(angle), sin(angle)) * vel,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final p = particle.progress;
                  final paint = Paint()
                    ..color = const Color(0xFFFF0055)
                        .withValues(alpha: 1.0 - p);
                  final r = (1.0 - p) * 4.0;
                  canvas.drawCircle(Offset.zero, r, paint);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final bodyPaint = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = const Color(0xFFFF0055).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, size.y)
      ..lineTo(size.x, 0)
      ..lineTo(size.x / 2, size.y * 0.3)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, bodyPaint);
  }
}
