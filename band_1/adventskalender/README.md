# Der Flutter-Code-Adventskalender
### In 24 Tagen zum leuchtenden Weihnachtsmarkt im Schneegestöber
**Die Flutter- & Dart-Werkstatt · Volker Dähn**

Dieses Verzeichnis enthält das vollständige Begleitprojekt zum Flutter-Code-Adventskalender – inklusive aller 24 aufeinander aufbauenden Entwicklungsschritte sowie dem finalen Meisterwerk.

---

## Projektstruktur

```text
code/adventskalender/
├── pubspec.yaml                          # Projekt-Konfiguration (Dart 3 / Flutter 3)
├── README.md                             # Diese Anleitung
└── lib/
    ├── main.dart                         # Interaktive Master-App mit Schritt-Auswahl (Tag 1–24)
    └── schritte/
        ├── tag_01_mitternachtshimmel.dart
        ├── tag_02_schneehuegel.dart
        ├── tag_03_tannenwald.dart
        ├── tag_04_sternenhimmel.dart
        ├── tag_05_mondsichel.dart
        ├── tag_06_markthuette.dart
        ├── tag_07_christbaum.dart
        ├── tag_08_baumkugeln.dart
        ├── tag_09_lichterkette.dart
        ├── tag_10_streifenmarkise.dart
        ├── tag_11_baumstern.dart
        ├── tag_12_responsives_layout.dart
        ├── tag_13_schneeflocke_modell.dart
        ├── tag_14_schneegestoeber.dart
        ├── tag_15_winterwind.dart
        ├── tag_16_interaktiver_wind.dart
        ├── tag_17_schneehauben.dart
        ├── tag_18_festliche_akustik.dart
        ├── tag_19_punschkessel.dart
        ├── tag_20_kaminfeuer.dart
        ├── tag_21_turmuhr.dart
        ├── tag_22_schneesturm_schalter.dart
        ├── tag_23_gold_typografie.dart
        └── tag_24_weihnachtsmarkt_vollversion.dart
```

---

## So startest du das Projekt

### 1. Interaktive Master-App starten
Öffne diesen Ordner in **VSCodium** und starte das Programm mit `F5` oder führe im Terminal aus:

```bash
flutter run
```

Mit dem Schieberegler am unteren Bildschirmrand oder den Pfeiltasten in der Titelleiste kannst du flüssig zwischen Tag 1 und Tag 24 wechseln und miterleben, wie die Winterlandschaft Stück für Stück entsteht.

### 2. Einen einzelnen Tag gezielt ausprobieren
Jede einzelne Datei im Ordner `lib/schritte/` besitzt ihre eigene `main()`-Funktion und ist vollkommen eigenständig lauffähig:

```bash
flutter run -t lib/schritte/tag_05_mondsichel.dart
```

Oder öffne die gewünschte Datei in VSCodium und drücke `F5`.

---

## Die 24 Tage im Überblick

1. **Tag 1: Der Mitternachtshimmel** – `LinearGradient` mit 3 Farbstopps
2. **Tag 2: Sanfte Schneehügel** – `CustomPaint` & quadratische Bézier-Kurven
3. **Tag 3: Tannenwald im Hintergrund** – Modulo-Arithmetik für unregelmäßige Baumketten
4. **Tag 4: Sternenhimmel** – Fester Pseudozufall mit `math.Random(101)`
5. **Tag 5: Die Mondsichel** – Pfad-Differenz mit `Path.combine`
6. **Tag 6: Erste Holzhütte** – Blockbohlen & warmes Fensterlicht
7. **Tag 7: Der große Christbaum** – Gestaffelte Nadelzweig-Etagen
8. **Tag 8: Glänzende Christbaumkugeln** – Plastische Reflexpunkte
9. **Tag 9: Pulsierende Lichterkette** – `AnimationController` & Weichzeichner
10. **Tag 10: Gestreifte Markisen** – Marktbuden-Atmosphäre
11. **Tag 11: Der goldene Baumstern** – 5-zackiger Stern über Polarkoordinaten
12. **Tag 12: Responsives Layout** – `LayoutBuilder` für jedes Bildschirmformat
13. **Tag 13: Schneeflocken-Datenmodell** – Saubere Dart-Klasse `Schneeflocke`
14. **Tag 14: Das Schneegestöber** – 180 fallende Partikel mit Recycling
15. **Tag 15: Winterwind & Taumeln** – Sinusförmige Drift-Physik
16. **Tag 16: Interaktiver Wind** – Wisch- & Mausgesten mit Dämpfung
17. **Tag 17: Liegender Schnee** – Schneehauben auf Giebeln & Ästen
18. **Tag 18: Festliche Akustik** – Audio-Architektur & Mute-Schalter
19. **Tag 19: Dampfender Punschkessel** – Partikel-Lebensdauer & Alpha-Fade
20. **Tag 20: Prasselndes Kaminfeuer** – Farbüberblendung mit `Color.lerp`
21. **Tag 21: Die historische Turmuhr** – Analoge Zeiger mit `DateTime.now()`
22. **Tag 22: Schneesturm-Turbotaste** – Dynamische Partikel-Eskalation
23. **Tag 23: Festliche Gold-Typografie** – Canvas-Schriftzug mit `TextPainter`
24. **Tag 24: Das fertige Meisterwerk** – Vollversion mit Release-Kompilierung

---

## Kompilieren als Desktop-App

Du kannst das fertige Projekt direkt als eigenständiges Programm auf deinem Desktop installieren:

```bash
# Unter Linux:
flutter build linux --release

# Unter Windows:
flutter build windows --release

# Unter macOS:
flutter build macos --release
```

Die fertige Binärdatei liegt anschließend im Ordner `build/<os>/runner/release/`.

---

© 2026 Volker Dähn · [flutter-werkstatt.de](https://www.flutter-werkstatt.de) · Schwesterbuchreihe: [rust-werkstatt.de](https://www.rust-werkstatt.de)
