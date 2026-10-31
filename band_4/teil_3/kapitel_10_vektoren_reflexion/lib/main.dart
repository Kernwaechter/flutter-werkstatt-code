import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: VectorReflexionGame.new,
    ),
  );
}

/// Physikalische Kugel mit Vektorberechnung und Reflexion
class PhysikKugel extends PositionComponent {
  Vector2 geschwindigkeit;
  final double radius;
  static const double schwerkraft = 400.0;
  late final Paint _pinsel;

  PhysikKugel({
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

    // 1. Schwerkraft-Vektor anwenden
    geschwindigkeit.y += schwerkraft * dt;

    // 2. Position aktualisieren
    position += geschwindigkeit * dt;

    // 3. Bildschirmraender mit Normalenvektoren reflektieren
    final game = findGame();
    if (game == null) return;

    // Boden: Normalenvektor zeigt nach oben (0, -1)
    if (position.y + radius >= game.size.y) {
      position.y = game.size.y - radius;
      _reflektiere(Vector2(0, -1), daempfung: 0.78);
    }
    // Decke: Normalenvektor zeigt nach unten (0, 1)
    if (position.y - radius <= 0) {
      position.y = radius;
      _reflektiere(Vector2(0, 1), daempfung: 0.85);
    }
    // Rechter Rand: Normalenvektor zeigt nach links (-1, 0)
    if (position.x + radius >= game.size.x) {
      position.x = game.size.x - radius;
      _reflektiere(Vector2(-1, 0), daempfung: 0.85);
    }
    // Linker Rand: Normalenvektor zeigt nach rechts (1, 0)
    if (position.x - radius <= 0) {
      position.x = radius;
      _reflektiere(Vector2(1, 0), daempfung: 0.85);
    }
  }

  /// Mathematische Vektor-Reflexion: v' = v - 2 * (v . n) * n
  void _reflektiere(Vector2 normale, {required double daempfung}) {
    final dotProduct = geschwindigkeit.dot(normale);
    if (dotProduct < 0) {
      final reflexionsImpuls = normale * (2.0 * dotProduct);
      final neuV = geschwindigkeit - reflexionsImpuls;
      geschwindigkeit = neuV * daempfung;
    }
  }

  void impuls(Vector2 richtung, double staerke) {
    geschwindigkeit += richtung.normalized() * staerke;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(radius, radius), radius, _pinsel);

    // Geschwindigkeits-Vektor als Linie einzeichnen
    final vLinie = geschwindigkeit * 0.15;
    final liniePinsel = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(radius, radius),
      Offset(radius + vLinie.x, radius + vLinie.y),
      liniePinsel,
    );
  }
}

/// Spiel: Klicke, um der Kugel einen Impuls-Vektor zu verpassen
class VectorReflexionGame extends FlameGame with TapCallbacks {
  late final PhysikKugel kugel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    kugel = PhysikKugel(
      position: Vector2(size.x * 0.5, size.y * 0.3),
      radius: 16.0,
      geschwindigkeit: Vector2(180, -100),
    );

    await add(kugel);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Klick erzeugt Impuls in Richtung des Klicks
    final klickPos = event.localPosition;
    final richtung = klickPos - kugel.position;
    kugel.impuls(richtung, 480.0);
  }

  @override
  Color backgroundColor() => const Color(0xFF0D131C);
}
