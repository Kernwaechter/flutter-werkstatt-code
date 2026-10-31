import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaesekaestchen/main.dart';

int spiele(Gegner a, Gegner b, math.Random r) {
  final feld = Spielfeld();
  var amZug = 1;
  var zuege = 0;
  while (!feld.istVoll) {
    final stufe = amZug == 1 ? a : b;
    final k = waehleComputerZug(feld, stufe, r);
    expect(feld.istGezogen(k), isFalse);
    if (feld.ziehe(k, amZug) == 0) amZug = 3 - amZug;
    zuege++;
  }
  expect(zuege, 40);
  expect(feld.freieKanten(), isEmpty);
  return feld.punkte(1) - feld.punkte(2);
}

void main() {
  test('Stufen schlagen sich gegenseitig', () {
    final r = math.Random(1);
    for (final paar in [
      [Gegner.mittel, Gegner.leicht],
      [Gegner.schwer, Gegner.mittel],
      [Gegner.schwer, Gegner.leicht],
    ]) {
      var siege = 0, nieder = 0;
      for (var i = 0; i < 200; i++) {
        // abwechselnd Anfang
        final d = i.isEven
            ? spiele(paar[0], paar[1], r)
            : -spiele(paar[1], paar[0], r);
        if (d > 0) siege++;
        if (d < 0) nieder++;
      }
      // ignore: avoid_print
      print('${paar[0].name} vs ${paar[1].name}: $siege : $nieder');
      expect(siege, greaterThan(nieder));
    }
  });
}
