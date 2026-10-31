import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF080810),
        body: GameWidget.controlled(gameFactory: ParticleLabGame.new),
      ),
    ),
  );
}

class ParticleLabGame extends FlameGame
    with TapCallbacks, DragCallbacks {
  final Random _rng = Random();
  late Vector2 _shipPos;
  double _shipAngle = 0.0;
  double _timer = 0.0;

  @override
  Color backgroundColor() => const Color(0xFF06070E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _shipPos = size / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Sanfte Kreisbahn des Raumschiffs zur Demonstration
    final radius = min(size.x, size.y) * 0.25;
    final center = size / 2;
    final targetPos = Vector2(
      center.x + cos(_timer * 1.5) * radius,
      center.y + sin(_timer * 1.5) * radius,
    );
    final moveDir = targetPos - _shipPos;
    if (moveDir.length > 0.1) {
      _shipAngle = atan2(moveDir.y, moveDir.x);
    }
    _shipPos = targetPos;

    // Kontinuierlicher Triebwerksschweif
    _spawnThrusterParticles();
  }

  void _spawnThrusterParticles() {
    // Partikel entgegen der Flugrichtung ausstossen
    final exhaustAngle = _shipAngle + pi;
    final exhaustDir = Vector2(cos(exhaustAngle), sin(exhaustAngle));
    final offset = exhaustDir * 16;
    final origin = _shipPos + offset;

    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 2,
          lifespan: 0.35,
          generator: (i) {
            final spread = (_rng.nextDouble() - 0.5) * 0.5;
            final speed = 80.0 + _rng.nextDouble() * 120.0;
            final angle = exhaustAngle + spread;
            final velocity = Vector2(cos(angle), sin(angle)) * speed;

            return AcceleratedParticle(
              position: origin.clone(),
              speed: velocity,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final progress = particle.progress;
                  final alpha = (1.0 - progress).clamp(0.0, 1.0);
                  final radius = (1.0 - progress) * 4.0;
                  final paint = Paint()
                    ..color = Color.lerp(
                      const Color(0xFF00FFFF),
                      const Color(0xFFFF0055),
                      progress,
                    )!.withValues(alpha: alpha);
                  canvas.drawCircle(Offset.zero, radius, paint);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void spawnExplosion(Vector2 origin) {
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 40,
          lifespan: 0.8,
          generator: (i) {
            final angle = _rng.nextDouble() * 2 * pi;
            final speed = 50.0 + _rng.nextDouble() * 250.0;
            final velocity = Vector2(cos(angle), sin(angle)) * speed;
            final colorHue = _rng.nextBool()
                ? const Color(0xFF00FFCC)
                : const Color(0xFFFF0077);

            return AcceleratedParticle(
              position: origin.clone(),
              speed: velocity,
              acceleration: -velocity * 0.8,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final p = particle.progress;
                  final alpha = (1.0 - p).clamp(0.0, 1.0);
                  final r = (1.0 - p) * 5.0 + 1.0;
                  final paint = Paint()
                    ..color = colorHue.withValues(alpha: alpha);
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
  void onTapDown(TapDownEvent event) {
    spawnExplosion(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    spawnExplosion(event.localEndPosition);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Raumschiff-Dreieck zeichnen
    canvas.save();
    canvas.translate(_shipPos.x, _shipPos.y);
    canvas.rotate(_shipAngle);

    final shipPaint = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final glowPaint = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(16, 0)
      ..lineTo(-12, -10)
      ..lineTo(-6, 0)
      ..lineTo(-12, 10)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, shipPaint);
    canvas.restore();

    final text = TextPainter(
      text: const TextSpan(
        text: 'Neon-Partikellabor: Tippe oder ziehe fuer Explosionen',
        style: TextStyle(
          color: Color(0xFF8899AA),
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(20, 20));
  }
}
