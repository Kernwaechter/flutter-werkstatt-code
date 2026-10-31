import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: GameWidget(
          game: AudioGame(),
          overlayBuilderMap: {
            'AudioHud': (context, AudioGame game) {
              return Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => game.playSfx('laser.wav'),
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Laser (Space)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => game.playSfx('explosion.wav'),
                      icon: const Icon(Icons.blur_on),
                      label: const Text('Explosion (E)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0055),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => game.playSfx('powerup.wav'),
                      icon: const Icon(Icons.star),
                      label: const Text('Powerup (P)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        game.isBgmPlaying
                            ? Icons.music_note
                            : Icons.music_off,
                        color: Colors.white,
                      ),
                      onPressed: game.toggleBgm,
                    ),
                  ],
                ),
              );
            },
          },
          initialActiveOverlays: const ['AudioHud'],
        ),
      ),
    ),
  );
}

class AudioGame extends FlameGame
    with KeyboardEvents, TapCallbacks {
  bool isBgmPlaying = false;
  double bgmVolume = 0.5;
  String lastPlayed = 'Druecke Leertaste, E oder P';

  @override
  Color backgroundColor() => const Color(0xFF0D0E15);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Audio-Dateien vorab in den Cache laden
    await FlameAudio.audioCache.loadAll([
      'laser.wav',
      'explosion.wav',
      'powerup.wav',
      'chiptune_loop.wav',
    ]);
  }

  void playSfx(String name) {
    FlameAudio.play(name, volume: 0.8);
    lastPlayed = 'Gespielt: $name';
  }

  void toggleBgm() {
    if (isBgmPlaying) {
      FlameAudio.bgm.stop();
      isBgmPlaying = false;
      lastPlayed = 'Hintergrundmusik pausiert';
    } else {
      FlameAudio.bgm.play('chiptune_loop.wav', volume: bgmVolume);
      isBgmPlaying = true;
      lastPlayed = 'Hintergrundmusik laeuft';
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    playSfx("laser.wav");
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        playSfx('laser.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        playSfx('explosion.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        playSfx('powerup.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyM) {
        toggleBgm();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '8-Bit Audio-Labor\n\n'
            'Status: $lastPlayed\n'
            'Tasten: [Leertaste] Laser | [E] Boese\n'
            '[P] Powerup | [M] BGM',
        style: const TextStyle(
          color: Color(0xFFE0E0FF),
          fontSize: 16,
          height: 1.5,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 48);

    textPainter.paint(canvas, const Offset(24, 60));
  }
}
