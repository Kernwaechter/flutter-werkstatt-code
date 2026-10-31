# Herkunft und Lizenz der Assets

Alle Bild-, Klang- und Shader-Dateien in diesem Repository sind für die
Buchreihe selbst erzeugt. Es wurde kein fremdes Material übernommen.
Teile davon hat der Autor mit Hilfe von Googles KI **Gemini** erzeugt
(siehe Tabelle).

## Lizenz: CC0 1.0 Universal

Die Assets stehen unter **CC0 1.0 Universal** (Public Domain Dedication,
<https://creativecommons.org/publicdomain/zero/1.0/deed.de>). Du darfst
sie ohne Namensnennung frei verwenden, auch kommerziell.

Soweit an KI-generierten Dateien überhaupt ein Urheberrecht entsteht,
räumt der Autor es mit dieser Erklärung vollständig ein. Eine Gewähr
dafür, dass die Dateien keine Rechte Dritter berühren, gibt es wie bei
jedem KI-Material nicht.

Der Programmcode steht dagegen unter der GPL (siehe `LICENSE`).

## Übersicht

| Dateien | Band | Herkunft |
|---------|------|----------|
| `*.wav` (Soundboard, Käsekästchen) | 1 | Mit Gemini erzeugt (KI-generiert) |
| `sneaker.png` | 1 | Mit Gemini erzeugt (KI-generiert) |
| `laser.wav`, `explosion.wav`, `powerup.wav`, `chiptune_loop.wav` | 4 | Prozedural synthetisiert mit `generate_audio_assets.py` |
| `runner_sheet.png`, `coin.png`, `rock.png`, `parallax_*.png` | 4 | Prozedural gezeichnet mit `generate_runner_assets.py` |
| `crt.frag` | 4 | Eigener GLSL-Shader, Teil des Programmcodes (GPL) |
| `libturbokrypto.so` | 3 | Aus `c_src/turbokrypto.c` gebaut (GPL) |

Schriftarten sind nicht enthalten. Die Beispiele nutzen die
Standardschriften von Flutter.

## Verwendete Pakete

| Paket | Lizenz |
|-------|--------|
| flutter, flutter_test, flutter_lints, path_provider, shared_preferences | BSD-3-Clause |
| http, path, crypto, ffi, html, forge2d | BSD-3-Clause |
| sensors_plus | BSD-3-Clause |
| sqflite, sqflite_common_ffi | BSD-2-Clause |
| flame, flame_audio, flame_forge2d, audioplayers | MIT |
| flutter_riverpod | MIT |

Alle genannten Lizenzen sind mit der GPL-3.0 vereinbar. Die genauen
Lizenztexte liegen in den jeweiligen Paketen auf <https://pub.dev>.
