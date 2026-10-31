import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0C1018),
        body: GameWidget.controlled(gameFactory: YSortingGame.new),
      ),
    ),
  );
}

class YSortingGame extends FlameGame
    with KeyboardEvents, TapCallbacks {
  static const double tileW = 64.0;
  static const double tileH = 32.0;
  static const int gridSize = 8;

  late PlayerCharacter player;
  Vector2 get origin => Vector2(size.x / 2, 90.0);

  Vector2 gridToScreen(double gx, double gy) {
    final sx = (gx - gy) * (tileW / 2) + origin.x;
    final sy = (gx + gy) * (tileH / 2) + origin.y;
    return Vector2(sx, sy);
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0D14);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Bodenkacheln
    for (int gx = 0; gx < gridSize; gx++) {
      for (int gy = 0; gy < gridSize; gy++) {
        add(IsoFloorTile(gx: gx, gy: gy));
      }
    }

    // Isometrische Saeulen / Hindernisse
    final pillars = [
      (2, 2),
      (2, 5),
      (5, 2),
      (5, 5),
    ];
    for (final p in pillars) {
      add(IsoPillar(gx: p.$1, gy: p.$2));
    }

    // Spieler-Figur
    player = PlayerCharacter(gx: 3.5, gy: 3.5);
    add(player);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return player.handleKey(keysPressed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Y-Sorting Demonstration\n'
            'Bewege die Spielfigur mit WASD oder Pfeiltasten.\n'
            'Beachte, wie die Figur vor und hinter\n'
            'den Saeulen wandert.',
        style: TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }
}

class IsoFloorTile extends Component
    with HasGameReference<YSortingGame> {
  final int gx;
  final int gy;
  IsoFloorTile({required this.gx, required this.gy});

  @override
  int get priority => -100; // Boden wird immer zuerst gerendert

  @override
  void render(Canvas canvas) {
    final top = game.gridToScreen(gx.toDouble(), gy.toDouble());
    final right = Vector2(top.x + YSortingGame.tileW / 2,
        top.y + YSortingGame.tileH / 2);
    final bottom = Vector2(top.x, top.y + YSortingGame.tileH);
    final left = Vector2(top.x - YSortingGame.tileW / 2,
        top.y + YSortingGame.tileH / 2);

    final path = Path()
      ..moveTo(top.x, top.y)
      ..lineTo(right.x, right.y)
      ..lineTo(bottom.x, bottom.y)
      ..lineTo(left.x, left.y)
      ..close();

    final paint = Paint()
      ..color = ((gx + gy) % 2 == 0)
          ? const Color(0xFF141C26)
          : const Color(0xFF192432)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = const Color(0xFF243242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }
}

class IsoPillar extends PositionComponent
    with HasGameReference<YSortingGame> {
  final int gx;
  final int gy;
  IsoPillar({required this.gx, required this.gy});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final basePos = game.gridToScreen(
      gx.toDouble(),
      gy.toDouble(),
    );
    // Position markiert den Standpunkt am Boden
    position = Vector2(
      basePos.x,
      basePos.y + YSortingGame.tileH / 2,
    );
    // Y-Sorting: Prioritaet entspricht der Y-Position am Boden
    priority = position.y.toInt();
  }

  @override
  void render(Canvas canvas) {
    const w = 24.0;
    const h = 50.0;

    // Saeulenschaft (Rechteck nach oben)
    final frontPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.fill;
    final topPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    final sidePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    // Frontflaeche
    canvas.drawRect(
      const Rect.fromLTWH(-w / 2, -h, w, h),
      frontPaint,
    );

    // Deckel (Dach)
    final topPath = Path()
      ..moveTo(0, -h - 8)
      ..lineTo(w / 2, -h)
      ..lineTo(0, -h + 8)
      ..lineTo(-w / 2, -h)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // Seitenkante
    canvas.drawLine(
      const Offset(w / 2, -h),
      const Offset(w / 2, 0),
      sidePaint,
    );
  }
}

class PlayerCharacter extends PositionComponent
    with HasGameReference<YSortingGame> {
  double gx;
  double gy;
  PlayerCharacter({required this.gx, required this.gy});

  final double speed = 3.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _updateScreenPos();
  }

  KeyEventResult handleKey(Set<LogicalKeyboardKey> keys) {
    double dx = 0;
    double dy = 0;

    if (keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp)) {
      dx -= 1;
      dy -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyS) ||
        keys.contains(LogicalKeyboardKey.arrowDown)) {
      dx += 1;
      dy += 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
      dy += 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
      dy -= 1;
    }

    if (dx != 0 || dy != 0) {
      gx = (gx + dx * 0.08).clamp(0.0, 7.0);
      gy = (gy + dy * 0.08).clamp(0.0, 7.0);
      _updateScreenPos();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _updateScreenPos() {
    final basePos = game.gridToScreen(gx, gy);
    position = Vector2(
      basePos.x,
      basePos.y + YSortingGame.tileH / 2,
    );
    // Dynamisches Y-Sorting waehrend der Bewegung!
    priority = position.y.toInt();
  }

  @override
  void render(Canvas canvas) {
    // Schatten am Boden
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTWH(-12, -4, 24, 10),
      shadowPaint,
    );

    // Spielfigur (blauer Roboter/Zylinder)
    final bodyPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -28, 20, 26),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Visier
    final visorPaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      const Rect.fromLTWH(-6, -24, 12, 6),
      visorPaint,
    );
  }
}
