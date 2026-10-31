import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:krypto_test_suite/main.dart';

void main() {
  group('KryptoRoutinen Unit-Tests', () {
    test('CRC32 deterministische Berechnung', () {
      final daten1 = utf8.encode('123456789');
      // Standard CRC-32 von "123456789" ist 0xCBF43926
      final crc = KryptoRoutinen.crc32(daten1);
      expect(crc, equals(0xCBF43926));
    });

    test('XOR Transform Invariante (doppelte Verschlüsselung)', () {
      final original = Uint8List.fromList([10, 20, 30, 40, 50]);
      const key = 0x42;
      final enc = KryptoRoutinen.xorTransform(original, key);
      final dec = KryptoRoutinen.xorTransform(enc, key);
      expect(dec, equals(original));
    });

    test('TOTP erzeugt 6-stelligen Zahlencode', () {
      final code = KryptoRoutinen.berechneTotp(
        geheimnis: 'GEHEIMER_SCHLUESSEL',
        zeitstempelSekunden: 1700000000,
      );
      expect(code.length, equals(6));
      expect(int.tryParse(code), isNotNull);
    });
  });

  testWidgets('Dashboard startet sauber und führt Tests aus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KryptoTestSuiteApp());

    expect(
      find.text('Krypto Test-Suite & Verifikation'),
      findsOneWidget,
    );
    expect(find.text('Noch keine Tests ausgeführt'), findsOneWidget);

    final button = find.text('Alle Krypto-Tests ausführen');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();

    expect(find.text('3 von 3 bestanden'), findsOneWidget);
  });
}
