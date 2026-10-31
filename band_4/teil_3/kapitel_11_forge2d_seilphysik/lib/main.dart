import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: SeilPhysikGame.new,
    ),
  );
}

/// Ein einzelnes Glied des Seils in Forge2D
class SeilGliedComponent extends BodyComponent {
  SeilGliedComponent({required Vector2 startPosition})
      : super(
          shapeSpecs: [
            ShapeSpec(
              Polygon.box(0.2, 0.7),
              ShapeDef(
                density: 2.0,
                material: SurfaceMaterial(friction: 0.4),
              ),
            ),
          ],
          bodyDef: BodyDef(
            position: startPosition,
            type: BodyType.dynamic,
            linearDamping: 0.1,
            angularDamping: 0.2,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;
  }
}

/// Statischer Deckenanker fuer das Seil
class SeilAnkerComponent extends BodyComponent {
  SeilAnkerComponent({required Vector2 ankerPosition})
      : super(
          shapeSpecs: [
            ShapeSpec(Circle(radius: 0.4)),
          ],
          bodyDef: BodyDef(
            position: ankerPosition,
            type: BodyType.static,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;
  }
}

/// Forge2D-Spiel mit mehrgliedriger Liane / schwingendem Seil
class SeilPhysikGame extends Forge2DGame with TapCallbacks {
  // 15 m/s^2 Schwerkraft im Physikraum
  SeilPhysikGame() : super(gravity: Vector2(0, 15.0));

  final List<SeilGliedComponent> glieder = [];
  late final SeilAnkerComponent anker;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Kamera zentrieren und auf 20 Pixel pro Meter zoomen
    camera.viewfinder.zoom = 20.0;
    camera.viewfinder.position = Vector2(0, 8);

    // 1. Statischen Aufhaengepunkt oben erzeugen
    anker = SeilAnkerComponent(ankerPosition: Vector2(0, 0));
    await world.add(anker);

    // 2. 7 Kettenglieder senkrecht nach unten verketten
    const gliedLaenge = 1.4;
    const anzahlGlieder = 7;
    Body vorherigerBody = anker.body;

    for (int i = 0; i < anzahlGlieder; i++) {
      final pos = Vector2(0, (i + 1) * gliedLaenge);
      final glied = SeilGliedComponent(startPosition: pos);
      await world.add(glied);
      glieder.add(glied);

      // Gelenk (RevoluteJoint) zwischen vorigem und aktuellem Glied
      final jointDef = RevoluteJointDef(
        bodyA: vorherigerBody,
        bodyB: glied.body,
        localAnchorA: Vector2(0, i == 0 ? 0.0 : 0.7),
        localAnchorB: Vector2(0, -0.7),
      );
      world.physicsWorld.createRevoluteJoint(jointDef);

      vorherigerBody = glied.body;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Dem untersten Glied einen seitlichen Schwung-Impuls geben
    if (glieder.isNotEmpty) {
      final unterstesGlied = glieder.last.body;
      unterstesGlied.applyLinearImpulse(Vector2(60.0, 0.0));
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF0C121A);
}
