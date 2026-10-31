# Die Flutter- & Dart-Werkstatt – Begleitcode

Hier liegen alle Beispielprogramme und Musterlösungen zur Buchreihe
**„Die Flutter- & Dart-Werkstatt“** von Volker Dähn.

Buchwebseite: <https://www.flutter-werkstatt.de>  
Repository: <https://github.com/Kernwaechter/flutter-werkstatt-code>

| Ordner   | Band                                                        |
|----------|-------------------------------------------------------------|
| `band_1/` | Vom ersten Widget zur eigenen App                          |
| `band_2/` | Architektur, Datenbanken und große Apps                    |
| `band_3/` | Hardware, IT-Sicherheit, Pakete und Veröffentlichung       |
| `band_4/` | 2D-Spieleentwicklung mit Flame                             |

Jeder Band ist nach den sechs Teilen des Buches gegliedert
(`teil_1/` bis `teil_6/`). In jedem Teil liegt ein Ordner pro Kapitel,
zum Beispiel `band_1/teil_3/kapitel_09_stateful_taste/`.

## So startest du ein Beispiel

Du brauchst Flutter (mindestens 3.47.8) und Dart (mindestens 3.13.7).
Öffne einen Kapitelordner in VSCodium (**File ➔ Open Folder**) und lege
einmalig die Startdateien für dein Betriebssystem an:

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` ergänzt nur die fehlenden Plattformordner und lässt
den Code im Ordner `lib/` unberührt.

## Lizenz

* **Programmcode:** GNU General Public License, Version 3 oder später
  (`GPL-3.0-or-later`), siehe Datei [`LICENSE`](LICENSE).
  Programme, die diesen Code verwenden, müssen ihrerseits wieder unter
  der GPL stehen.
* **Bilder, Klänge und Shader:** selbst erzeugt und gemeinfrei
  (CC0 1.0), siehe [`ASSETS.md`](ASSETS.md).
* **Verwendete Pakete** (Flutter, Flame, Riverpod und andere) behalten
  ihre eigenen Lizenzen. Alle sind permissiv (BSD oder MIT) und mit der
  GPL vereinbar.
* **Buchtext, Abbildungen und Cover** gehören nicht zu diesem
  Repository und sind urheberrechtlich geschützt.

Copyright © 2026 Volker Dähn

## Fehler gefunden?

Eröffne ein Issue oder schreib mir über die Buchwebseite.
