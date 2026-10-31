import 'dart:math';
import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF04050A),
        body: GameWidget.controlled(gameFactory: ShaderLabGame.new),
      ),
    ),
  );
}

class ShaderLabGame extends FlameGame with TapCallbacks {
  FragmentShader? _crtShader;
  double _elapsed = 0.0;
  bool _shaderActive = true;

  @override
  Color backgroundColor() => const Color(0xFF04060C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final program = await FragmentProgram.fromAsset(
      'shaders/crt.frag',
    );
    _crtShader = program.fragmentShader();

    // Dynamische Neon-Gitterlinien als Hintergrund
    add(NeonGridComponent());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _shaderActive = !_shaderActive;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // GLSL Shader als Post-Processing-Layer zeichnen
    final shader = _crtShader;
    if (shader != null && _shaderActive) {
      shader.setFloat(0, size.x);
      shader.setFloat(1, size.y);
      shader.setFloat(2, _elapsed);
      shader.setFloat(3, _shaderActive ? 1.0 : 0.0);

      final paint = Paint()..shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
    }

    // UI-Hinweis zeichnen
    final status = _shaderActive ? 'AKTIV' : 'AUS';
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'GLSL CRT-Shader: $status\n'
            'Tippe auf den Bildschirm zum Umschalten',
        style: const TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(20, 24));
  }
}

class NeonGridComponent extends Component
    with HasGameReference<ShaderLabGame> {
  double _time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    final offsetX = (_time * 20.0) % spacing;

    for (double x = -spacing + offsetX;
        x < size.x + spacing;
        x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // Rotierender Neon-Polyeder
    final center = size / 2;
    canvas.save();
    canvas.translate(center.x, center.y);
    canvas.rotate(_time * 0.8);

    final polyPaint = Paint()
      ..color = const Color(0xFFFF0077)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const radius = 60.0;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final px = cos(angle) * radius;
      final py = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, polyPaint);
    canvas.restore();
  }
}
