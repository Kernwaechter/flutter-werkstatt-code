import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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

    final pfad = join(await getDatabasesPath(), 'sammlung_kap12.db');

    return await openDatabase(
      pfad,
      // Version 2 mit Migration!
      version: 2,
      onCreate: (db, version) async {
        // Frische Installation: direkt das komplette Schema Version 2
        await db.execute('''
          CREATE TABLE sammlungsstuecke (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titel TEXT NOT NULL,
            kategorie TEXT NOT NULL,
            schaetzwert REAL NOT NULL,
            kaufpreis REAL DEFAULT 0.0,
            zustand TEXT NOT NULL
          )
        ''');

        await db.insert('sammlungsstuecke', {
          'titel': 'Commodore 64 (Brotkasten)',
          'kategorie': 'Computer',
          'schaetzwert': 250.0,
          'kaufpreis': 40.0,
          'zustand': 'Sehr gut',
        });
        await db.insert('sammlungsstuecke', {
          'titel': 'Super Nintendo mit OVP',
          'kategorie': 'Konsole',
          'schaetzwert': 180.0,
          'kaufpreis': 25.0,
          'zustand': 'Sammlerzustand',
        });
        await db.insert('sammlungsstuecke', {
          'titel': 'Sony Walkman WM-DD',
          'kategorie': 'Audio',
          'schaetzwert': 320.0,
          'kaufpreis': 15.0,
          'zustand': 'Gut',
        });
      },
      onUpgrade: (db, alteVersion, neueVersion) async {
        // Saubere Migration: Wenn ein Nutzer von Version 1 kommt,
        // fuegen wir die neue Spalte kaufpreis hinzu!
        if (alteVersion < 2) {
          await db.execute('''
            ALTER TABLE sammlungsstuecke
            ADD COLUMN kaufpreis REAL DEFAULT 0.0
          ''');
        }
      },
    );
  }

  static Future<List<Sammlungsstueck>> ladeAlle() async {
    final db = await datenbank;
    final ergebnis =
        await db.query('sammlungsstuecke', orderBy: 'titel ASC');
    return ergebnis.map((m) => Sammlungsstueck.fromMap(m)).toList();
  }

  static Future<int> einfuegen(Sammlungsstueck stueck) async {
    final db = await datenbank;
    return await db.insert('sammlungsstuecke', stueck.toMap());
  }

  static Future<int> loeschen(int id) async {
    final db = await datenbank;
    return await db.delete(
      'sammlungsstuecke',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Backup als JSON-Datei exportieren
  static Future<String> exportiereBackup() async {
    final db = await datenbank;
    final alle = await db.query('sammlungsstuecke');

    final jsonString = const JsonEncoder.withIndent('  ').convert(alle);

    final dir = await getApplicationDocumentsDirectory();
    final datei = File(join(dir.path, 'sammlung_backup.json'));
    await datei.writeAsString(jsonString);

    return datei.path;
  }

  // Backup aus JSON-Datei wiederherstellen (mit Transaktion!)
  static Future<int> importiereBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final datei = File(join(dir.path, 'sammlung_backup.json'));

    if (!await datei.exists()) {
      throw Exception('Keine Backup-Datei gefunden!');
    }

    final inhalt = await datei.readAsString();
    final daten = jsonDecode(inhalt) as List<dynamic>;

    final db = await datenbank;

    // Transaktion: Entweder alles klappt oder nichts wird veraendert
    await db.transaction((txn) async {
      await txn.delete('sammlungsstuecke');
      for (final eintrag in daten) {
        final map = Map<String, Object?>.from(eintrag as Map);
        await txn.insert('sammlungsstuecke', map);
      }
    });

    return daten.length;
  }
}
