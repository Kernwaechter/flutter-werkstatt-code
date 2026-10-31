import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const GameWidget.controlled(
      gameFactory: WerkbankGameLoop.new,
    ),
  );
}

/// Minimaler Flame-Game-Loop zur Veranschaulichung von update(dt)
/// und render(canvas).
class WerkbankGameLoop extends FlameGame {
  // Position und Geschwindigkeit des Balls in Pixeln
  double _posX = 100.0;
  double _posY = 100.0;
  double _velX = 220.0;
  double _velY = 160.0;
  static const double _ballRadius = 14.0;

  // Stoppuhr fuer FPS- und Laufzeit-Statistiken
  double _laufzeitSekunden = 0.0;
  int _frameZaehler = 0;
  double _aktuelleFps = 60.0;

  // Farben und Zeichenpinsel (Paint)
  late final Paint _ballPinsel;
  late final Paint _spurenPinsel;
  late final TextPaint _textPinsel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Dunkler Retro-Hintergrund mit leuchtendem Werkbank-Gruen
    _ballPinsel = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;

    // Sanfte Bewegungskontur
    _spurenPinsel = Paint()
      ..color = const Color(0xFF00FF66).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _textPinsel = TextPaint(
      style: const TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 14.0,
        fontFamily: 'monospace',
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Statistik erfassen
    _laufzeitSekunden += dt;
    _frameZaehler++;
    if (_laufzeitSekunden >= 0.5) {
      _aktuelleFps = _frameZaehler / _laufzeitSekunden;
      _frameZaehler = 0;
      _laufzeitSekunden = 0.0;
    }

    // Positionsupdate exakt skaliert mit Delta-Time (dt)
    _posX += _velX * dt;
    _posY += _velY * dt;

    // Kollision mit den Bildschirmraendern (Abprallen)
    final breite = size.x;
    final hoehe = size.y;

    if (_posX - _ballRadius <= 0) {
      _posX = _ballRadius;
      _velX = -_velX;
    } else if (_posX + _ballRadius >= breite) {
      _posX = breite - _ballRadius;
      _velX = -_velX;
    }

    if (_posY - _ballRadius <= 0) {
      _posY = _ballRadius;
      _velY = -_velY;
    } else if (_posY + _ballRadius >= hoehe) {
      _posY = hoehe - _ballRadius;
      _velY = -_velY;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Ball zeichnen
    final mittelpunkt = Offset(_posX, _posY);
    canvas.drawCircle(mittelpunkt, _ballRadius + 4.0, _spurenPinsel);
    canvas.drawCircle(mittelpunkt, _ballRadius, _ballPinsel);

    // Debug-Anzeige im Röhren-Look
    final safeFps = _aktuelleFps > 0 ? _aktuelleFps : 60;
    final frameSekunden = 1.0 / safeFps;
    final fpsText = 'FPS: ${_aktuelleFps.toStringAsFixed(1)} | '
        'dt: ${frameSekunden.toStringAsFixed(4)}s';
    _textPinsel.render(canvas, fpsText, Vector2(16.0, 16.0));

    final posText = 'Pos: (${_posX.toInt()}, ${_posY.toInt()}) | '
        'Feld: ${size.x.toInt()} x ${size.y.toInt()}';
    _textPinsel.render(canvas, posText, Vector2(16.0, 36.0));
  }

  @override
  Color backgroundColor() => const Color(0xFF101418);
}
