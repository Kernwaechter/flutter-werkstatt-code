# Begleitcode zu „Die Flutter- & Dart-Werkstatt – Band 1“

In diesem Ordner findest du alle Beispielprogramme und Musterlösungen aus Band 1, geordnet nach den sechs Teilen des Buches.

## So nutzt du die Beispiele in VSCodium

Es gibt zwei Möglichkeiten, wie du den Code aus diesem Ordner verwenden kannst:

### Möglichkeit 1: Die Datei `lib/main.dart` in dein bestehendes Übungsprojekt übernehmen (Empfohlen)
Wenn du in VSCodium bereits dein eigenes Projekt (z. B. `hallo_werkstatt`) geöffnet hast, kannst du in den jeweiligen Kapitelordner schauen, die Datei `lib/main.dart` öffnen und mit deiner eigenen Datei vergleichen.

### Möglichkeit 2: Einen Kapitelordner direkt als Projekt starten
Jeder Unterordner enthält die Datei `pubspec.yaml` und den Ordner `lib/`. Wenn du einen Ordner direkt in VSCodium öffnest (**File ➔ Open Folder**), führe im Ordner einmalig über die Befehlspalette (`Strg + Umschalt + P` bzw. `Cmd + Umschalt + P`) den Befehl **`Flutter: Get Packages`** aus (oder lege mit `flutter create .` die plattformspezifischen Startdateien für dein Betriebssystem an), bevor du auf **Run** drückst.

---

## Übersicht der enthaltenen Programme

* **`teil_1/` – Die Werkbank und das erste Fenster**
  * `kapitel_03_hallo_werkstatt/` – Das erste eigene Fenster aus Kapitel 3
  * `kapitel_04_schild_gestalten/` – Das gestaltete Willkommensschild mit Variablen und dunklem Hintergrund aus Kapitel 4
  * `kapitel_04_loesung_namensschild/` – Musterlösung zu „Zeig was Du kannst“ aus Kapitel 4 (helles Namensschild mit sanftem Kontrast)
* **`teil_2/` – Projekt 1: Der digitale Sneaker-Karton**
  * `kapitel_05_column_und_row/` – Spalten, Zeilen und Schriftgewichte aus Kapitel 5
  * `kapitel_06_bilder_und_kaesten/` – `Container`, abgerundete Ecken und `Image.asset` (inkl. `assets/sneaker.png`) aus Kapitel 6
  * `kapitel_07_padding_und_expanded/` – `Padding`, `SizedBox`, `Expanded` und Kauf-Knopf im 8-Punkt-Raster aus Kapitel 7
  * `kapitel_08_eigene_bausteine/` – Eigene `StatelessWidget`-Bausteine (`GroessenKachel` und `SneakerKarte`) aus Kapitel 8
  * `kapitel_08_loesung_zwei_karten/` – Musterlösung zu Kapitel 8 (zwei verschiedene Sneaker-Karten nebeneinander)
* **`teil_3/` – Projekt 2: Das Soundboard**
  * `kapitel_09_stateful_taste/` – Die erste interaktive Sound-Taste mit `StatefulWidget` und `setState` aus Kapitel 9
  * `kapitel_10_soundboard_raster/` – Das 3x3-Soundboard-Raster (`GridView.count`) mit „Zustand nach oben heben“ (*Lifting State Up*) aus Kapitel 10
  * `kapitel_11_sound_ausgabe/` – Das komplette Studio-Soundboard mit dem Paket `audioplayers`, Lautstärke-`Slider`, Stopp-Knopf und 9 fertigen `.wav`-Klängen in `assets/sounds/` (Kapitel 11 & 12)
  * `kapitel_11_loesung_mix_modus/` – Musterlösung mit Synthwave-Orange-Design (60-30-10-Regel) und umschaltbarem Solo-/Mix-Modus
* **`teil_4/` – Projekt 3: Schulhelfer 1.0** *(folgt mit Teil 4)*
* **`teil_5/` – Projekt 4: Der Vertretungsplan-Veredeler** *(folgt mit Teil 5)*
* **`teil_6/` – Projekt 5: Käsekästchen mit Computergegner**
  * `kapitel_21_punkteraster/` – Punkteraster mit `CustomPainter` zeichnen und Kanten per `GestureDetector` antippen (Kapitel 21)
  * `kapitel_22_regelwerk/` – Regelwerk für zwei Spieler am selben Gerät: Kästchen schließen, Extrazug, Sieg (Kapitel 22)
  * `kapitel_23_computergegner/` – Der Computergegner mit drei Schwierigkeitsstufen und Nachdenkpause (Kapitel 23)
  * `kapitel_24_kaesekaestchen_komplett/` – Das fertige Spiel mit Animationen, Sounds in `assets/sounds/`, Statistik über `shared_preferences` und Tests (Kapitel 24)

---

## Lizenz: Freie Software unter GPL

Der Programmcode in diesem Ordner steht unter der **GNU General Public License, Version 3 oder später** (GPL-3.0-or-later). Den vollständigen Text findest du in der Datei `LICENSE`.

* Du darfst den Code frei verwenden, lesen, verändern und weitergeben, privat, in der Schule und kommerziell.
* Programme, die diesen Code oder Teile davon verwenden, müssen ihrerseits unter der GPL stehen. Wer sie weitergibt, muss auch ihren Quelltext frei zugänglich machen.
* Copyright © 2026 Volker Dähn.
* Das gesamte Begleitmaterial zu allen vier Bänden findest du auch auf GitHub: <https://github.com/Kernwaechter/flutter-werkstatt-code>

Diese Lizenz gilt nur für den Programmcode. Der Text des Buches, die Abbildungen und die Cover sind urheberrechtlich geschützt und dürfen nicht weitergegeben werden (siehe Impressum im Buch). Die verwendeten Pakete, etwa Flutter, Flame oder Drift, behalten ihre eigenen Lizenzen.

---

## Lizenz: Freie Software unter GPL

Der Programmcode in diesem Ordner steht unter der **GNU General Public License, Version 3 oder später** (GPL-3.0-or-later). Den vollständigen Text findest du in der Datei `LICENSE`.

* Du darfst den Code frei verwenden, lesen, verändern und weitergeben, privat, in der Schule und kommerziell.
* Programme, die diesen Code oder Teile davon verwenden, müssen ihrerseits unter der GPL stehen. Wer sie weitergibt, muss auch ihren Quelltext frei zugänglich machen.
* Copyright © 2026 Volker Dähn.
* Das gesamte Begleitmaterial zu allen vier Bänden findest du auch auf GitHub: <https://github.com/Kernwaechter/flutter-werkstatt-code>

Diese Lizenz gilt nur für den Programmcode. Der Text des Buches, die Abbildungen und die Cover sind urheberrechtlich geschützt und dürfen nicht weitergegeben werden (siehe Impressum im Buch). Die verwendeten Pakete, etwa Flutter, Flame oder Drift, behalten ihre eigenen Lizenzen.
