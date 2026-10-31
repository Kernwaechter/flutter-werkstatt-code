import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide PointerMoveEvent;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0F141C),
        body: GameWidget.controlled(gameFactory: IsoMathGame.new),
      ),
    ),
  );
}

class IsoMathGame extends FlameGame
    with TapCallbacks, PointerMoveCallbacks {
  static const double tileW = 64.0;
  static const double tileH = 32.0;
  static const int gridSize = 8;

  Point<int>? hoveredTile;
  Point<int>? selectedTile;

  Vector2 get origin => Vector2(size.x / 2, 80.0);

  Vector2 gridToScreen(int gx, int gy) {
    final sx = (gx - gy) * (tileW / 2) + origin.x;
    final sy = (gx + gy) * (tileH / 2) + origin.y;
    return Vector2(sx, sy);
  }

  Point<int>? screenToGrid(Vector2 screenPos) {
    final dx = screenPos.x - origin.x;
    final dy = screenPos.y - origin.y;
    final gx = ((dx / (tileW / 2) + dy / (tileH / 2)) / 2).floor();
    final gy = ((dy / (tileH / 2) - dx / (tileW / 2)) / 2).floor();

    if (gx >= 0 && gx < gridSize && gy >= 0 && gy < gridSize) {
      return Point(gx, gy);
    }
    return null;
  }

  @override
  Color backgroundColor() => const Color(0xFF0B0F16);

  @override
  void onPointerMove(PointerMoveEvent event) {
    hoveredTile = screenToGrid(event.localPosition);
  }

  @override
  void onTapDown(TapDownEvent event) {
    selectedTile = screenToGrid(event.localPosition);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Isometrisches Rauten-Gitter zeichnen
    for (int gx = 0; gx < gridSize; gx++) {
      for (int gy = 0; gy < gridSize; gy++) {
        _renderIsoTile(canvas, gx, gy);
      }
    }

    // Koordinaten-HUD
    final hoverStr = hoveredTile != null
        ? 'Hover: (${hoveredTile!.x}, ${hoveredTile!.y})'
        : 'Hover: ausserhalb';
    final selStr = selectedTile != null
        ? 'Ausgewaehlt: (${selectedTile!.x}, ${selectedTile!.y})'
        : 'Ausgewaehlt: keine';

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Isometrische Projektion (2:1 Rhombus)\n'
            '$hoverStr | $selStr\n'
            'Bewege die Maus und klicke auf Kacheln',
        style: const TextStyle(
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

  void _renderIsoTile(Canvas canvas, int gx, int gy) {
    final top = gridToScreen(gx, gy);
    final right = Vector2(top.x + tileW / 2, top.y + tileH / 2);
    final bottom = Vector2(top.x, top.y + tileH);
    final left = Vector2(top.x - tileW / 2, top.y + tileH / 2);

    final path = Path()
      ..moveTo(top.x, top.y)
      ..lineTo(right.x, right.y)
      ..lineTo(bottom.x, bottom.y)
      ..lineTo(left.x, left.y)
      ..close();

    Color fillColor = const Color(0xFF16202C);
    if (selectedTile?.x == gx && selectedTile?.y == gy) {
      fillColor = const Color(0xFF00FFCC).withValues(alpha: 0.6);
    } else if (hoveredTile?.x == gx && hoveredTile?.y == gy) {
      fillColor = const Color(0xFF00B0FF).withValues(alpha: 0.35);
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }
}

class Point<T extends num> {
  final T x;
  final T y;
  const Point(this.x, this.y);
}
