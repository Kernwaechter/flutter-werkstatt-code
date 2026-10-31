import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: HitboxDemoGame.new,
    ),
  );
}

/// Statisches Hindernis mit Rechteck-Hitbox
class HindernisBlock extends PositionComponent
    with CollisionCallbacks {
  final Color farbe;
  late final Paint _pinsel;

  HindernisBlock({
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

    // Hitbox montieren
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _pinsel);
  }
}

/// Fliegender Ball mit Kreis-Hitbox und Kollisions-Rueckmeldung
class KollisionsBall extends PositionComponent
    with CollisionCallbacks {
  Vector2 geschwindigkeit;
  final double radius;
  Color aktuelleFarbe = const Color(0xFF00FF66);
  late final Paint _pinsel;

  KollisionsBall({
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
    _pinsel = Paint()..style = PaintingStyle.fill;
    // Kreisfoermige Trefferzone
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += geschwindigkeit * dt;

    // Ränder abprallen
    final parentGame = findGame();
    if (parentGame != null) {
      if (position.x - radius <= 0 ||
          position.x + radius >= parentGame.size.x) {
        geschwindigkeit.x = -geschwindigkeit.x;
      }
      if (position.y - radius <= 0 ||
          position.y + radius >= parentGame.size.y) {
        geschwindigkeit.y = -geschwindigkeit.y;
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is HindernisBlock) {
      // Bei Treffer abprallen und Farbe wechseln
      geschwindigkeit.x = -geschwindigkeit.x;
      aktuelleFarbe = const Color(0xFFFF0055);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    aktuelleFarbe = const Color(0xFF00FF66);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _pinsel.color = aktuelleFarbe;
    canvas.drawCircle(Offset(radius, radius), radius, _pinsel);
  }
}

/// Hauptspiel mit aktiviertem HasCollisionDetection
class HitboxDemoGame extends FlameGame with HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2 Felsbloecke platzieren
    await add(
      HindernisBlock(
        position: Vector2(size.x * 0.3, size.y * 0.5),
        size: Vector2(50, 140),
        farbe: const Color(0xFF455A64),
      ),
    );

    await add(
      HindernisBlock(
        position: Vector2(size.x * 0.7, size.y * 0.5),
        size: Vector2(50, 140),
        farbe: const Color(0xFF455A64),
      ),
    );

    // Ball starten
    await add(
      KollisionsBall(
        position: Vector2(size.x * 0.5, size.y * 0.5),
        radius: 14.0,
        geschwindigkeit: Vector2(240, 150),
      ),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0E14);
}
