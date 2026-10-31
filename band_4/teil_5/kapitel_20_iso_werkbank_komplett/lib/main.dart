import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF090D14),
        body: GameWidget.controlled(
          gameFactory: IsoWerkbankGame.new,
          overlayBuilderMap: {
            'MissionAccomplished': (context, IsoWerkbankGame game) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101824)
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
                        'MISSION ERFUELLT!',
                        style: TextStyle(
                          fontSize: 28,
                          color: Color(0xFF00FFCC),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Alle Werkzeuge gesichert.',
                        style: TextStyle(
                          fontSize: 16,
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
                            horizontal: 28,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('NOCHMAL SPIELEN'),
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

class IsoWerkbankGame extends FlameGame with TapCallbacks {
  static const double tileW = 64.0;
  static const double tileH = 32.0;
  static const int gridSize = 8;

  Vector2 get origin => Vector2(size.x / 2, 70.0);

  // 0 = Boden, 1 = Wand/Maschine
  final List<List<int>> grid = List.generate(
    gridSize,
    (x) => List.generate(gridSize, (y) => 0),
  );

  late IsoPlayer player;
  late SecurityDrone drone;
  final List<IsoItem> items = [];
  int collectedCount = 0;
  static const int totalItems = 3;

  Vector2 gridToScreen(double gx, double gy) {
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
  Color backgroundColor() => const Color(0xFF070A10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _setupLevel();
  }

  void _setupLevel() {
    // Mauern definieren
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        grid[x][y] = 0;
      }
    }
    final walls = [
      const Point(2, 1),
      const Point(2, 2),
      const Point(2, 3),
      const Point(5, 4),
      const Point(5, 5),
      const Point(5, 6),
    ];
    for (final w in walls) {
      grid[w.x][w.y] = 1;
    }

    // Bodenkacheln
    for (int gx = 0; gx < gridSize; gx++) {
      for (int gy = 0; gy < gridSize; gy++) {
        final isW = grid[gx][gy] == 1;
        add(IsoTileComponent(gx: gx, gy: gy, isWall: isW));
      }
    }

    // Spieler
    player = IsoPlayer(startPos: const Point(0, 0));
    add(player);

    // Drohne
    drone = SecurityDrone(
      patrolPath: [
        const Point(1, 6),
        const Point(4, 6),
        const Point(4, 1),
        const Point(1, 1),
      ],
    );
    add(drone);

    // Werkzeuge
    _spawnItems();
  }

  void _spawnItems() {
    final itemPositions = [
      const Point(1, 3),
      const Point(6, 2),
      const Point(7, 6),
    ];
    for (final p in itemPositions) {
      final item = IsoItem(pos: p);
      items.add(item);
      add(item);
    }
  }

  void restartGame() {
    overlays.remove('MissionAccomplished');
    collectedCount = 0;
    for (final item in children.whereType<IsoItem>()) {
      item.removeFromParent();
    }
    items.clear();
    _spawnItems();
    player.reset(const Point(0, 0));
    drone.reset();
    resumeEngine();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final clicked = screenToGrid(event.localPosition);
    if (clicked != null && grid[clicked.x][clicked.y] == 0) {
      player.moveTo(clicked);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Pruefe Item-Aufnahme
    for (final item in items.toList()) {
      if (!item.isCollected &&
          player.gridPos.x == item.pos.x &&
          player.gridPos.y == item.pos.y) {
        item.collect();
        collectedCount++;
        if (collectedCount >= totalItems) {
          overlays.add('MissionAccomplished');
          pauseEngine();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final droneState = drone.aiState.name.toUpperCase();
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ISO-WERKBANK (Desktop-Isometrie)\n'
            'Items: $collectedCount / $totalItems | '
            'Drohne KI: $droneState\n'
            'Klicke mit der Maus,\n'
            'um den Mechaniker per A* zu fuehren',
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
}

class IsoTileComponent extends Component
    with HasGameReference<IsoWerkbankGame> {
  final int gx;
  final int gy;
  final bool isWall;

  IsoTileComponent({
    required this.gx,
    required this.gy,
    required this.isWall,
  });

  @override
  int get priority => isWall ? (gy * 100 + gx) : -50;

  @override
  void render(Canvas canvas) {
    final top = game.gridToScreen(gx.toDouble(), gy.toDouble());
    final right = Vector2(top.x + IsoWerkbankGame.tileW / 2,
        top.y + IsoWerkbankGame.tileH / 2);
    final bottom = Vector2(top.x, top.y + IsoWerkbankGame.tileH);
    final left = Vector2(top.x - IsoWerkbankGame.tileW / 2,
        top.y + IsoWerkbankGame.tileH / 2);

    final path = Path()
      ..moveTo(top.x, top.y)
      ..lineTo(right.x, right.y)
      ..lineTo(bottom.x, bottom.y)
      ..lineTo(left.x, left.y)
      ..close();

    if (isWall) {
      // 3D-Klotz fuer Wand
      const wallHeight = 28.0;
      final wallFront = Path()
        ..moveTo(left.x, left.y)
        ..lineTo(bottom.x, bottom.y)
        ..lineTo(bottom.x, bottom.y - wallHeight)
        ..lineTo(left.x, left.y - wallHeight)
        ..close();

      final wallSide = Path()
        ..moveTo(bottom.x, bottom.y)
        ..lineTo(right.x, right.y)
        ..lineTo(right.x, right.y - wallHeight)
        ..lineTo(bottom.x, bottom.y - wallHeight)
        ..close();

      final wallTop = Path()
        ..moveTo(top.x, top.y - wallHeight)
        ..lineTo(right.x, right.y - wallHeight)
        ..lineTo(bottom.x, bottom.y - wallHeight)
        ..lineTo(left.x, left.y - wallHeight)
        ..close();

      canvas.drawPath(
        wallFront,
        Paint()..color = const Color(0xFF1E2838),
      );
      canvas.drawPath(
        wallSide,
        Paint()..color = const Color(0xFF161F2C),
      );
      canvas.drawPath(
        wallTop,
        Paint()..color = const Color(0xFF2A374A),
      );
    } else {
      final color = ((gx + gy) % 2 == 0)
          ? const Color(0xFF121822)
          : const Color(0xFF161E2A);
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF222C3C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }
}

class IsoPlayer extends PositionComponent
    with HasGameReference<IsoWerkbankGame> {
  Point<int> gridPos;
  final List<Point<int>> _waypoints = [];
  double _moveProgress = 0.0;
  Point<int>? _currentTarget;

  IsoPlayer({required Point<int> startPos})
      : gridPos = startPos,
        super();

  void reset(Point<int> pos) {
    gridPos = pos;
    _waypoints.clear();
    _currentTarget = null;
    _moveProgress = 0.0;
    _updateScreenPos(pos.x.toDouble(), pos.y.toDouble());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _updateScreenPos(gridPos.x.toDouble(), gridPos.y.toDouble());
  }

  void moveTo(Point<int> goal) {
    final path = IsoAStar.solve(
      start: gridPos,
      goal: goal,
      grid: game.grid,
      size: IsoWerkbankGame.gridSize,
    );
    if (path.length > 1) {
      _waypoints.clear();
      _waypoints.addAll(path.sublist(1));
      _currentTarget = _waypoints.removeAt(0);
      _moveProgress = 0.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentTarget != null) {
      _moveProgress += dt * 3.5;
      if (_moveProgress >= 1.0) {
        gridPos = _currentTarget!;
        if (_waypoints.isNotEmpty) {
          _currentTarget = _waypoints.removeAt(0);
          _moveProgress = 0.0;
        } else {
          _currentTarget = null;
          _moveProgress = 0.0;
        }
      }

      final startX = gridPos.x.toDouble();
      final startY = gridPos.y.toDouble();
      final targetX = (_currentTarget ?? gridPos).x.toDouble();
      final targetY = (_currentTarget ?? gridPos).y.toDouble();

      final currentX = startX + (targetX - startX) * _moveProgress;
      final currentY = startY + (targetY - startY) * _moveProgress;
      _updateScreenPos(currentX, currentY);
    }
  }

  void _updateScreenPos(double gx, double gy) {
    final pos = game.gridToScreen(gx, gy);
    position = Vector2(
      pos.x,
      pos.y + IsoWerkbankGame.tileH / 2,
    );
    priority = position.y.toInt();
  }

  @override
  void render(Canvas canvas) {
    // Schatten
    canvas.drawOval(
      const Rect.fromLTWH(-10, -3, 20, 8),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Koerper
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -26, 16, 24),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF00FFCC),
    );

    // Helm / Visier
    canvas.drawRect(
      const Rect.fromLTWH(-5, -22, 10, 5),
      Paint()..color = const Color(0xFF0F1722),
    );
  }
}

enum DroneState { patrol, chase, returning }

class SecurityDrone extends PositionComponent
    with HasGameReference<IsoWerkbankGame> {
  final List<Point<int>> patrolPath;
  int _patrolIndex = 0;
  DroneState aiState = DroneState.patrol;
  Point<int> currentGrid;
  Point<int>? nextTile;
  double progress = 0.0;

  SecurityDrone({required this.patrolPath})
      : currentGrid = patrolPath.first,
        super();

  void reset() {
    _patrolIndex = 0;
    currentGrid = patrolPath.first;
    nextTile = null;
    progress = 0.0;
    aiState = DroneState.patrol;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final cx = currentGrid.x.toDouble();
    final cy = currentGrid.y.toDouble();
    _updateScreenPos(cx, cy);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final dx = (currentGrid.x - game.player.gridPos.x).abs();
    final dy = (currentGrid.y - game.player.gridPos.y).abs();
    final distToPlayer = dx + dy;

    // KI-Zustandsuebergaenge
    if (distToPlayer <= 3 && game.player.gridPos != currentGrid) {
      aiState = DroneState.chase;
    } else if (aiState == DroneState.chase && distToPlayer > 4) {
      aiState = DroneState.patrol;
    }

    if (nextTile == null) {
      if (aiState == DroneState.chase) {
        final path = IsoAStar.solve(
          start: currentGrid,
          goal: game.player.gridPos,
          grid: game.grid,
          size: IsoWerkbankGame.gridSize,
        );
        if (path.length > 1) {
          nextTile = path[1];
        }
      } else {
        // Patrouille zum naechsten Wegpunkt
        final target = patrolPath[_patrolIndex];
        if (currentGrid == target) {
          _patrolIndex = (_patrolIndex + 1) % patrolPath.length;
        }
        final path = IsoAStar.solve(
          start: currentGrid,
          goal: patrolPath[_patrolIndex],
          grid: game.grid,
          size: IsoWerkbankGame.gridSize,
        );
        if (path.length > 1) {
          nextTile = path[1];
        }
      }
    }

    if (nextTile != null) {
      progress += dt * 2.2;
      if (progress >= 1.0) {
        currentGrid = nextTile!;
        nextTile = null;
        progress = 0.0;
      }

      final startX = currentGrid.x.toDouble();
      final startY = currentGrid.y.toDouble();
      final endX = (nextTile ?? currentGrid).x.toDouble();
      final endY = (nextTile ?? currentGrid).y.toDouble();

      final cx = startX + (endX - startX) * progress;
      final cy = startY + (endY - startY) * progress;
      _updateScreenPos(cx, cy);
    }
  }

  void _updateScreenPos(double gx, double gy) {
    final pos = game.gridToScreen(gx, gy);
    position = Vector2(
      pos.x,
      pos.y + IsoWerkbankGame.tileH / 2,
    );
    priority = position.y.toInt() + 1;
  }

  @override
  void render(Canvas canvas) {
    // Schatten
    canvas.drawOval(
      const Rect.fromLTWH(-8, -2, 16, 6),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Schwebende Drohne (Rautenform)
    final color = (aiState == DroneState.chase)
        ? const Color(0xFFFF0055)
        : const Color(0xFFFFD600);

    final path = Path()
      ..moveTo(0, -28)
      ..lineTo(10, -22)
      ..lineTo(0, -16)
      ..lineTo(-10, -22)
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    // Rote Sensor-Linse
    canvas.drawCircle(
      const Offset(0, -22),
      3.0,
      Paint()..color = Colors.white,
    );
  }
}

class IsoItem extends PositionComponent
    with HasGameReference<IsoWerkbankGame> {
  final Point<int> pos;
  bool isCollected = false;

  IsoItem({required this.pos});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final p = game.gridToScreen(pos.x.toDouble(), pos.y.toDouble());
    position = Vector2(
      p.x,
      p.y + IsoWerkbankGame.tileH / 2,
    );
    priority = position.y.toInt() - 1;
  }

  void collect() {
    isCollected = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (isCollected) return;

    // Schraubenschluessel / Werkzeug-Icon
    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(0, -10), 5, paint);
    canvas.drawRect(const Rect.fromLTWH(-2, -8, 4, 10), paint);
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

class IsoAStar {
  static List<Point<int>> solve({
    required Point<int> start,
    required Point<int> goal,
    required List<List<int>> grid,
    required int size,
  }) {
    if (start == goal) return [start];

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
      openList.sort((a, b) => a.fCost.compareTo(b.fCost));
      final current = openList.removeAt(0);

      if (current.pos == goal) {
        final path = <Point<int>>[];
        _AStarNode? curr = current;
        while (curr != null) {
          path.insert(0, curr.pos);
          curr = curr.parent;
        }
        return path;
      }

      closedSet.add(current.pos);

      const dirs = [
        Point(0, -1),
        Point(0, 1),
        Point(-1, 0),
        Point(1, 0),
      ];

      for (final dir in dirs) {
        final nx = current.pos.x + dir.x;
        final ny = current.pos.y + dir.y;
        final neighborPos = Point(nx, ny);

        if (nx < 0 || nx >= size || ny < 0 || ny >= size) continue;
        if (grid[nx][ny] == 1) continue;
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
    return [];
  }

  static double _heuristic(Point<int> a, Point<int> b) {
    return ((a.x - b.x).abs() + (a.y - b.y).abs()).toDouble();
  }
}
