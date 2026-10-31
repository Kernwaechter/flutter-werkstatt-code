import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DschungelSchwungApp());
}

/// App-Huelle mit HUD- und Status-Overlays
class DschungelSchwungApp extends StatelessWidget {
  const DschungelSchwungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget<DschungelSchwungGame>.controlled(
          gameFactory: DschungelSchwungGame.new,
          overlayBuilderMap: {
            'HUD': (context, game) => SchwungHud(game: game),
            'GameOver': (context, game) => StatusDialog(
                  titel: 'IN DIE GRUBE GEFALLEN!',
                  farbe: const Color(0xFFFF0055),
                  buttonText: 'NOCHMAL VERSUCHEN',
                  onAction: game.neustart,
                ),
            'Sieg': (context, game) => StatusDialog(
                  titel: 'ABGRUND GEMEISTERT!',
                  farbe: const Color(0xFF00FF66),
                  buttonText: 'NAECHSTE RUNDE',
                  onAction: game.neustart,
                ),
          },
          initialActiveOverlays: const ['HUD'],
        ),
      ),
    );
  }
}

/// HUD-Anzeige
class SchwungHud extends StatelessWidget {
  final DschungelSchwungGame game;
  const SchwungHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF101418).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFF00FF66)),
          ),
          child: const Text(
            'A/D: Laufen | Leertaste: Springen / Seil loslassen',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14.0,
              color: Color(0xFF00FF66),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status-Dialog fuer Sieg und Niederlage
class StatusDialog extends StatelessWidget {
  final String titel;
  final Color farbe;
  final String buttonText;
  final VoidCallback onAction;

  const StatusDialog({
    super.key,
    required this.titel,
    required this.farbe,
    required this.buttonText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320.0,
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(
          color: const Color(0xFF101418).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: farbe, width: 2.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: farbe,
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: farbe,
                foregroundColor: Colors.black,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feste Plattformen (Start links, Ziel rechts)
class PlattformComponent extends BodyComponent {
  final Vector2 plattformPos;
  final Vector2 halbeGroesse;

  PlattformComponent({
    required this.plattformPos,
    required this.halbeGroesse,
  }) : super(
          shapeSpecs: [
            ShapeSpec(
              Polygon.box(halbeGroesse.x, halbeGroesse.y),
              ShapeDef(
                material: SurfaceMaterial(friction: 0.6),
              ),
            ),
          ],
          bodyDef: BodyDef(
            position: plattformPos,
            type: BodyType.static,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;
  }
}

/// Seilglied
class LianeGlied extends BodyComponent {
  LianeGlied({required Vector2 startPos})
      : super(
          shapeSpecs: [
            ShapeSpec(
              Polygon.box(0.18, 0.65),
              ShapeDef(
                density: 2.0,
                material: SurfaceMaterial(friction: 0.8),
              ),
            ),
          ],
          bodyDef: BodyDef(
            position: startPos,
            type: BodyType.dynamic,
            linearDamping: 0.05,
            angularDamping: 0.1,
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

/// Statischer Anker
class LianeAnker extends BodyComponent {
  LianeAnker({required Vector2 ankerPos})
      : super(
          shapeSpecs: [ShapeSpec(Circle(radius: 0.35))],
          bodyDef: BodyDef(
            position: ankerPos,
            type: BodyType.static,
          ),
        );
}

/// Der Pitfall-Abenteurer
class Abenteurer extends BodyComponent {
  bool amSeil = false;
  WeldJoint? seilVerbindung;

  Abenteurer({required Vector2 startPos})
      : super(
          shapeSpecs: [
            ShapeSpec(
              Polygon.box(0.5, 0.9),
              ShapeDef(
                density: 1.5,
                material: SurfaceMaterial(
                  friction: 0.2,
                  restitution: 0.0,
                ),
              ),
            ),
          ],
          bodyDef: BodyDef(
            position: startPos,
            type: BodyType.dynamic,
            fixedRotation: true,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;
  }

  void laufe(double richtung) {
    if (!amSeil) {
      final vy = body.linearVelocity.y;
      body.linearVelocity = Vector2(richtung * 8.0, vy);
    }
  }

  void springeOderLassLos(DschungelSchwungGame game) {
    if (amSeil) {
      // Vom Seil abspringen
      final vJoint = seilVerbindung;
      if (vJoint != null) {
        vJoint.destroy();
        seilVerbindung = null;
      }
      amSeil = false;
      // Schwung-Impuls nach oben-rechts mitgeben
      body.applyLinearImpulse(Vector2(12.0, -18.0));
    } else {
      // Sprung vom Boden
      body.applyLinearImpulse(Vector2(0, -16.0));
    }
  }
}

/// Das Hauptspiel
class DschungelSchwungGame extends Forge2DGame
    with KeyboardEvents, TapCallbacks {
  DschungelSchwungGame() : super(gravity: Vector2(0, 16.0));

  late final Abenteurer spieler;
  final List<LianeGlied> lianenGlieder = [];
  bool isVorbei = false;

  final Set<LogicalKeyboardKey> _tasten = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.zoom = 18.0;
    camera.viewfinder.position = Vector2(0, 6.0);

    // 1. Startplattform links
    await world.add(
      PlattformComponent(
        plattformPos: Vector2(-12.0, 8.0),
        halbeGroesse: Vector2(4.0, 1.0),
      ),
    );

    // 2. Zielplattform rechts
    await world.add(
      PlattformComponent(
        plattformPos: Vector2(12.0, 8.0),
        halbeGroesse: Vector2(4.0, 1.0),
      ),
    );

    // 3. Schwingende Liane in der Mitte
    final anker = LianeAnker(ankerPos: Vector2(0, -4.0));
    await world.add(anker);

    Body vorher = anker.body;
    const gliederAnzahl = 8;
    for (int i = 0; i < gliederAnzahl; i++) {
      final yPos = -4.0 + (i + 1) * 1.3;
      final glied = LianeGlied(startPos: Vector2(0, yPos));
      await world.add(glied);
      lianenGlieder.add(glied);

      final jDef = RevoluteJointDef(
        bodyA: vorher,
        bodyB: glied.body,
        localAnchorA: Vector2(0, i == 0 ? 0 : 0.65),
        localAnchorB: Vector2(0, -0.65),
      );
      world.physicsWorld.createRevoluteJoint(jDef);
      vorher = glied.body;
    }

    // Anfangs-Schwung fuer das Seil
    lianenGlieder.last.body.applyLinearImpulse(Vector2(35.0, 0));

    // 4. Spieler auf Startplattform setzen
    spieler = Abenteurer(startPos: Vector2(-12.0, 6.0));
    await world.add(spieler);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _tasten.clear();
    _tasten.addAll(keysPressed);

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.keyW)) {
      if (!isVorbei) {
        spieler.springeOderLassLos(this);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isVorbei) return;

    // 1. Horizontale Bewegung
    double richtung = 0.0;
    if (_tasten.contains(LogicalKeyboardKey.keyA) ||
        _tasten.contains(LogicalKeyboardKey.arrowLeft)) {
      richtung -= 1.0;
    }
    if (_tasten.contains(LogicalKeyboardKey.keyD) ||
        _tasten.contains(LogicalKeyboardKey.arrowRight)) {
      richtung += 1.0;
    }
    spieler.laufe(richtung);

    // 2. An Liane greifen pruefen
    if (!spieler.amSeil && lianenGlieder.isNotEmpty) {
      final unterstesGlied = lianenGlieder.last;
      final posA = spieler.body.position;
      final posB = unterstesGlied.body.position;
      final distanz = (posA - posB).length;

      // Wenn nahe genug am unteren Ende des Seils: Einklinken
      if (distanz < 1.4 && spieler.body.position.y < 8.0) {
        spieler.amSeil = true;
        spieler.body.position.setFrom(unterstesGlied.body.position);

        final wDef = WeldJointDef(
          bodyA: unterstesGlied.body,
          bodyB: spieler.body,
        );
        spieler.seilVerbindung =
            world.physicsWorld.createWeldJoint(wDef);
      }
    }

    // 3. Am Seil mitschwingen (Momentum verstaerken)
    if (spieler.amSeil && richtung != 0.0) {
      lianenGlieder.last.body.applyLinearImpulse(
        Vector2(richtung * 18.0 * dt, 0),
      );
    }

    // 4. Gewinn- und Verlustbedingungen
    if (spieler.body.position.y > 12.0) {
      isVorbei = true;
      pauseEngine();
      overlays.add('GameOver');
    } else if (spieler.body.position.x > 9.0 &&
        spieler.body.position.y < 7.5) {
      isVorbei = true;
      pauseEngine();
      overlays.add('Sieg');
    }
  }

  void neustart() {
    isVorbei = false;
    overlays.remove('GameOver');
    overlays.remove('Sieg');

    final seilJ = spieler.seilVerbindung;
    if (seilJ != null) {
      seilJ.destroy();
      spieler.seilVerbindung = null;
    }
    spieler.amSeil = false;

    // Position zuruecksetzen
    spieler.body.position.setValues(-12.0, 6.0);
    spieler.body.linearVelocity.setZero();

    // Seil beruhigen und leichten Schwung geben
    for (final glied in lianenGlieder) {
      glied.body.linearVelocity.setZero();
      glied.body.angularVelocity = 0.0;
    }
    lianenGlieder.last.body.applyLinearImpulse(Vector2(35.0, 0));

    resumeEngine();
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0F16);
}
