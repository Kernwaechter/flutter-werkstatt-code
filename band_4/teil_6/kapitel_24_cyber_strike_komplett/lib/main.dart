import 'dart:math';
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
        backgroundColor: const Color(0xFF04060C),
        body: GameWidget.controlled(
          gameFactory: CyberStrikeGame.new,
          overlayBuilderMap: {
            'Victory': (context, CyberStrikeGame game) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1420)
                        .withValues(alpha: 0.94),
                    border: Border.all(
                      color: const Color(0xFF00FFCC),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SEKTOR GESAEUBERT!',
                        style: TextStyle(
                          fontSize: 28,
                          color: Color(0xFF00FFCC),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Alle Reaktoren wurden zerstoert.',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: game.restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFCC),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('NOCHMAL KAMPF'),
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

class CyberStrikeGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  late CyberTank player;
  int coresRemaining = 3;
  bool isGameOver = false;

  @override
  Color backgroundColor() => const Color(0xFF04060C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await FlameAudio.audioCache.loadAll([
      'laser.wav',
      'explosion.wav',
      'powerup.wav',
      'chiptune_loop.wav',
    ]);
    FlameAudio.bgm.play('chiptune_loop.wav', volume: 0.35);

    _setupBattlefield();
  }

  void _setupBattlefield() {
    world.add(CyberGrid());

    // 3 feindliche Energie-Reaktoren
    final reactorPos = [
      Vector2(-250, -180),
      Vector2(250, -180),
      Vector2(0, 220),
    ];
    for (final pos in reactorPos) {
      world.add(PowerCore(position: pos));
    }

    // Spieler-Panzer
    player = CyberTank(position: Vector2(0, 0));
    world.add(player);

    camera.viewfinder.zoom = 1.0;
    camera.follow(player);
  }

  void playSfx(String name) {
    FlameAudio.play(name, volume: 0.7);
  }

  void onCoreDestroyed() {
    coresRemaining--;
    if (coresRemaining <= 0) {
      isGameOver = true;
      overlays.add('Victory');
      pauseEngine();
    }
  }

  void restartGame() {
    overlays.remove('Victory');
    coresRemaining = 3;
    isGameOver = false;

    for (final c in world.children.whereType<PowerCore>()) {
      c.removeFromParent();
    }
    for (final b in world.children.whereType<EnergyBolt>()) {
      b.removeFromParent();
    }

    final reactorPos = [
      Vector2(-250, -180),
      Vector2(250, -180),
      Vector2(0, 220),
    ];
    for (final pos in reactorPos) {
      world.add(PowerCore(position: pos));
    }

    player.position = Vector2(0, 0);
    player.health = 100;
    resumeEngine();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isGameOver) {
      player.fire();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CYBER-STRIKE HD | PANZERUNG: ${player.health}% | '
            'REAKTOREN: $coresRemaining\n'
            'Tasten: [WASD / Pfeile] Steuern\n'
            '[Leertaste / Klick] Laser',
        style: const TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 14,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }
}

class CyberGrid extends Component {
  @override
  void render(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF0F1A2A)
      ..strokeWidth = 1.0;

    const span = 900.0;
    const step = 60.0;
    for (double x = -span; x <= span; x += step) {
      canvas.drawLine(Offset(x, -span), Offset(x, span), linePaint);
    }
    for (double y = -span; y <= span; y += step) {
      canvas.drawLine(Offset(-span, y), Offset(span, y), linePaint);
    }
  }
}

class CyberTank extends PositionComponent
    with HasGameReference<CyberStrikeGame>, CollisionCallbacks {
  CyberTank({required Vector2 position})
      : super(
          position: position,
          size: Vector2(44, 44),
          anchor: Anchor.center,
        );

  double heading = 0.0;
  double speed = 0.0;
  int health = 100;
  double fireCooldown = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 18, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    fireCooldown = max(0.0, fireCooldown - dt);

    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      heading -= 3.2 * dt;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      heading += 3.2 * dt;
    }

    if (keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp)) {
      speed = (speed + 450.0 * dt).clamp(0.0, 240.0);
    } else if (keys.contains(LogicalKeyboardKey.keyS) ||
        keys.contains(LogicalKeyboardKey.arrowDown)) {
      speed = (speed - 350.0 * dt).clamp(-140.0, 240.0);
    } else {
      if (speed > 0) speed = max(0.0, speed - 260.0 * dt);
      if (speed < 0) speed = min(0.0, speed + 260.0 * dt);
    }

    if (keys.contains(LogicalKeyboardKey.space)) {
      fire();
    }

    position.x += cos(heading) * speed * dt;
    position.y += sin(heading) * speed * dt;

    position.x = position.x.clamp(-800.0, 800.0);
    position.y = position.y.clamp(-800.0, 800.0);
  }

  void fire() {
    if (fireCooldown > 0.0) return;
    fireCooldown = 0.18;
    game.playSfx('laser.wav');

    final muzzle = Vector2(
      position.x + cos(heading) * 26.0,
      position.y + sin(heading) * 26.0,
    );
    game.world.add(EnergyBolt(position: muzzle, angle: heading));
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(heading);

    // HD-Vektor Chassis
    final bodyFill = Paint()
      ..color = const Color(0xFF0B1220)
      ..style = PaintingStyle.fill;
    final bodyStroke = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(16, 0)
      ..lineTo(6, -14)
      ..lineTo(-16, -14)
      ..lineTo(-12, 0)
      ..lineTo(-16, 14)
      ..lineTo(6, 14)
      ..close();

    canvas.drawPath(path, bodyFill);
    canvas.drawPath(path, bodyStroke);

    // Turm
    final turretPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 8, turretPaint);

    // Rohr
    final barrelPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, const Offset(20, 0), barrelPaint);

    canvas.restore();
  }
}

class EnergyBolt extends PositionComponent
    with CollisionCallbacks, HasGameReference<CyberStrikeGame> {
  final double speed = 650.0;
  double lifeTimer = 1.2;

  EnergyBolt({required Vector2 position, required double angle})
      : super(
          position: position,
          angle: angle,
          size: Vector2(16, 4),
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
    position.x += cos(angle) * speed * dt;
    position.y += sin(angle) * speed * dt;

    lifeTimer -= dt;
    if (lifeTimer <= 0.0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(angle);
    final paint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -2, 16, 4),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.restore();
  }
}

class PowerCore extends PositionComponent
    with CollisionCallbacks, HasGameReference<CyberStrikeGame> {
  PowerCore({required Vector2 position})
      : super(
          position: position,
          size: Vector2(48, 48),
          anchor: Anchor.center,
        );

  int coreHp = 5;
  double pulse = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 22, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    pulse += dt * 3.0;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnergyBolt) {
      other.removeFromParent();
      coreHp--;
      game.playSfx('explosion.wav');

      if (coreHp <= 0) {
        _explode();
        game.onCoreDestroyed();
        removeFromParent();
      }
    }
  }

  void _explode() {
    game.world.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 35,
          lifespan: 0.7,
          generator: (i) {
            final ang = Random().nextDouble() * 2 * pi;
            final vel = 40.0 + Random().nextDouble() * 200.0;
            return AcceleratedParticle(
              position: position.clone(),
              speed: Vector2(cos(ang), sin(ang)) * vel,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final p = particle.progress;
                  final paint = Paint()
                    ..color = const Color(0xFFFF0055)
                        .withValues(alpha: 1.0 - p);
                  final r = (1.0 - p) * 5.0;
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
    final scale = 1.0 + sin(pulse) * 0.08;
    canvas.save();
    canvas.scale(scale);

    final coreFill = Paint()
      ..color = const Color(0xFFFF0055).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final coreStroke = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset.zero, 18, coreFill);
    canvas.drawCircle(Offset.zero, 18, coreStroke);

    // Innerer Energie-Kern
    final innerPaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 8, innerPaint);

    canvas.restore();
  }
}
