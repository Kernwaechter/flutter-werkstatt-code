import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/sammlungsstueck.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get datenbank async {
    if (_db != null) return _db!;
    _db = await _initialisiereDb();
    return _db!;
  }

  static Future<Database> _initialisiereDb() async {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final pfad = join(await getDatabasesPath(), 'sammlung_kap10.db');

    return await openDatabase(
      pfad,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sammlungsstuecke (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titel TEXT NOT NULL,
            kategorie TEXT NOT NULL,
            schaetzwert REAL NOT NULL,
            zustand TEXT NOT NULL,
            notiz TEXT
          )
        ''');

        // Beispiel-Datensaetze beim ersten Anlegen
        await db.insert('sammlungsstuecke', {
          'titel': 'Commodore 64 (Brotkasten)',
          'kategorie': 'Computer',
          'schaetzwert': 250.0,
          'zustand': 'Sehr gut',
          'notiz': 'Original-Netzteil vorhanden',
        });
        await db.insert('sammlungsstuecke', {
          'titel': 'Super Nintendo mit OVP',
          'kategorie': 'Konsole',
          'schaetzwert': 180.0,
          'zustand': 'Sammlerzustand',
          'notiz': 'Inkl. Super Mario World',
        });
        await db.insert('sammlungsstuecke', {
          'titel': 'Sony Walkman WM-DD',
          'kategorie': 'Audio',
          'schaetzwert': 320.0,
          'zustand': 'Gut',
          'notiz': 'Antriebsriemen frisch getauscht',
        });
      },
    );
  }

  static Future<int> einfuegen(Sammlungsstueck stueck) async {
    final db = await datenbank;
    return await db.insert('sammlungsstuecke', stueck.toMap());
  }

  // Sichere parametrisierte Suche (Schutz vor SQL-Injections!)
  static Future<List<Sammlungsstueck>> suchen({
    String suchtext = '',
    String kategorie = 'Alle',
    String sortierung = 'titel_asc',
  }) async {
    final db = await datenbank;

    final whereBedingungen = <String>[];
    final whereArgumente = <Object?>[];

    if (suchtext.trim().isNotEmpty) {
      whereBedingungen.add('titel LIKE ?');
      whereArgumente.add('%${suchtext.trim()}%');
    }

    if (kategorie != 'Alle') {
      whereBedingungen.add('kategorie = ?');
      whereArgumente.add(kategorie);
    }

    final whereKlausel =
        whereBedingungen.isEmpty ? null : whereBedingungen.join(' AND ');

    String orderBy;
    switch (sortierung) {
      case 'wert_desc':
        orderBy = 'schaetzwert DESC';
        break;
      case 'wert_asc':
        orderBy = 'schaetzwert ASC';
        break;
      case 'titel_desc':
        orderBy = 'titel DESC';
        break;
      case 'titel_asc':
      default:
        orderBy = 'titel ASC';
        break;
    }

    final ergebnis = await db.query(
      'sammlungsstuecke',
      where: whereKlausel,
      whereArgs: whereArgumente.isEmpty ? null : whereArgumente,
      orderBy: orderBy,
    );

    return ergebnis.map((m) => Sammlungsstueck.fromMap(m)).toList();
  }

  static Future<int> aktualisieren(Sammlungsstueck stueck) async {
    final db = await datenbank;
    return await db.update(
      'sammlungsstuecke',
      stueck.toMap(),
      where: 'id = ?',
      whereArgs: [stueck.id],
    );
  }

  static Future<int> loeschen(int id) async {
    final db = await datenbank;
    return await db.delete(
      'sammlungsstuecke',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<double> berechneGesamtwert() async {
    final db = await datenbank;
    final ergebnis = await db.rawQuery(
      'SELECT SUM(schaetzwert) as summe FROM sammlungsstuecke',
    );
    final wert = ergebnis.first['summe'];
    if (wert == null) return 0.0;
    return (wert as num).toDouble();
  }
}
