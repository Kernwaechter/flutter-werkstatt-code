import 'dart:collection';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0C1018),
        body: GameWidget.controlled(gameFactory: AStarLabGame.new),
      ),
    ),
  );
}

class AStarLabGame extends FlameGame with TapCallbacks {
  static const double tileW = 60.0;
  static const double tileH = 30.0;
  static const int gridSize = 9;

  Vector2 get origin => Vector2(size.x / 2, 70.0);

  // 0 = frei, 1 = Mauer/Hindernis
  final List<List<int>> grid = List.generate(
    gridSize,
    (x) => List.generate(gridSize, (y) => 0),
  );

  Point<int> start = const Point(1, 1);
  Point<int> target = const Point(7, 7);
  List<Point<int>> currentPath = [];

  @override
  Color backgroundColor() => const Color(0xFF090C12);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Feste Mauern fuer Testlabyrinth
    final walls = [
      const Point(3, 1),
      const Point(3, 2),
      const Point(3, 3),
      const Point(3, 4),
      const Point(5, 4),
      const Point(5, 5),
      const Point(5, 6),
      const Point(5, 7),
    ];
    for (final w in walls) {
      grid[w.x][w.y] = 1;
    }

    _findPath();
  }

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
  void onTapDown(TapDownEvent event) {
    final clicked = screenToGrid(event.localPosition);
    if (clicked != null) {
      if (grid[clicked.x][clicked.y] == 1) {
        // Klick auf Mauer loescht sie
        grid[clicked.x][clicked.y] = 0;
      } else if (clicked == start) {
        // Ignorieren
      } else {
        // Neues Ziel setzen
        target = clicked;
      }
      _findPath();
    }
  }

  void _findPath() {
    currentPath = AStarSolver.solve(
      start: start,
      goal: target,
      grid: grid,
      size: gridSize,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Kacheln zeichnen
    for (int gx = 0; gx < gridSize; gx++) {
      for (int gy = 0; gy < gridSize; gy++) {
        _renderIsoTile(canvas, gx, gy);
      }
    }

    // HUD
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'A*-Wegfindung auf Isometrie-Gitter\n'
            'Start: (${start.x}, ${start.y}) | '
            'Ziel: (${target.x}, ${target.y})\n'
            'Pfadlaenge: ${currentPath.length} Schritte\n'
            'Klicke auf das Gitter, um ein neues Ziel zu setzen',
        style: const TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.4,
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

    final isWall = grid[gx][gy] == 1;
    final isPath = currentPath.contains(Point(gx, gy));
    final isStart = start == Point(gx, gy);
    final isGoal = target == Point(gx, gy);

    Color color;
    if (isStart) {
      color = const Color(0xFF00E5FF);
    } else if (isGoal) {
      color = const Color(0xFFFFD600);
    } else if (isWall) {
      color = const Color(0xFFFF0055);
    } else if (isPath) {
      color = const Color(0xFF00FF66).withValues(alpha: 0.7);
    } else {
      color = ((gx + gy) % 2 == 0)
          ? const Color(0xFF141C26)
          : const Color(0xFF192432);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF283648)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }
}

class Point<T extends num> {
  final T x;
  final T y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class _AStarNode {
  final Point<int> pos;
  final double gCost;
  final double hCost;
  final _AStarNode? parent;

  _AStarNode({
    required this.pos,
    required this.gCost,
    required this.hCost,
    this.parent,
  });

  double get fCost => gCost + hCost;
}

class AStarSolver {
  static List<Point<int>> solve({
    required Point<int> start,
    required Point<int> goal,
    required List<List<int>> grid,
    required int size,
  }) {
    final openList = <_AStarNode>[];
    final closedSet = HashSet<Point<int>>();

    openList.add(
      _AStarNode(
        pos: start,
        gCost: 0,
        hCost: _heuristic(start, goal),
      ),
    );

    while (openList.isNotEmpty) {
      // Knoten mit geringstem fCost waehlen
      openList.sort((a, b) => a.fCost.compareTo(b.fCost));
      final current = openList.removeAt(0);

      if (current.pos == goal) {
        // Pfad rekonstruieren
        final path = <Point<int>>[];
        _AStarNode? curr = current;
        while (curr != null) {
          path.insert(0, curr.pos);
          curr = curr.parent;
        }
        return path;
      }

      closedSet.add(current.pos);

      // 4-Wege-Nachbarn (N, S, W, O)
      const directions = [
        Point(0, -1),
        Point(0, 1),
        Point(-1, 0),
        Point(1, 0),
      ];

      for (final dir in directions) {
        final nx = current.pos.x + dir.x;
        final ny = current.pos.y + dir.y;
        final neighborPos = Point(nx, ny);

        if (nx < 0 || nx >= size || ny < 0 || ny >= size) continue;
        if (grid[nx][ny] == 1) continue; // Mauer
        if (closedSet.contains(neighborPos)) continue;

        final newGCost = current.gCost + 1.0;
        final existing = openList
            .where((n) => n.pos == neighborPos)
            .firstOrNull;

        if (existing == null) {
          openList.add(
            _AStarNode(
              pos: neighborPos,
              gCost: newGCost,
              hCost: _heuristic(neighborPos, goal),
              parent: current,
            ),
          );
        } else if (newGCost < existing.gCost) {
          openList.remove(existing);
          openList.add(
            _AStarNode(
              pos: neighborPos,
              gCost: newGCost,
              hCost: _heuristic(neighborPos, goal),
              parent: current,
            ),
          );
        }
      }
    }

    return []; // Kein Pfad gefunden
  }

  static double _heuristic(Point<int> a, Point<int> b) {
    // Manhattan-Distanz
    return ((a.x - b.x).abs() + (a.y - b.y).abs()).toDouble();
  }
}
