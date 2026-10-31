import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/sammlungsstueck.dart';
import '../models/standort.dart';

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

    final pfad = join(await getDatabasesPath(), 'sammlung_kap11.db');

    return await openDatabase(
      pfad,
      version: 1,
      onConfigure: (db) async {
        // Fremdschluessel-Pruefung in SQLite explizit aktivieren
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // 1. Tabelle fuer Standorte (Eltern-Tabelle)
        await db.execute('''
          CREATE TABLE standorte (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            beschreibung TEXT
          )
        ''');

        // 2. Tabelle fuer Sammlungsstuecke mit Fremdschluessel
        await db.execute('''
          CREATE TABLE sammlungsstuecke (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titel TEXT NOT NULL,
            kategorie TEXT NOT NULL,
            schaetzwert REAL NOT NULL,
            zustand TEXT NOT NULL,
            standort_id INTEGER,
            FOREIGN KEY (standort_id) REFERENCES standorte (id)
              ON DELETE SET NULL
          )
        ''');

        // Standard-Standorte anlegen
        final s1 = await db.insert('standorte', {
          'name': 'Vitrine 1 (Wohnzimmer)',
          'beschreibung': 'Glastuere, staubgeschuetzt',
        });
        final s2 = await db.insert('standorte', {
          'name': 'Regal A2 (Kellerarchiv)',
          'beschreibung': 'Trocken und dunkel',
        });
        final s3 = await db.insert('standorte', {
          'name': 'Regal B1 (Arbeitszimmer)',
          'beschreibung': 'Direkt am Schreibtisch',
        });

        // Beispiel-Stuecke mit Verknuepfung
        await db.insert('sammlungsstuecke', {
          'titel': 'Commodore 64 (Brotkasten)',
          'kategorie': 'Computer',
          'schaetzwert': 250.0,
          'zustand': 'Sehr gut',
          'standort_id': s2,
        });
        await db.insert('sammlungsstuecke', {
          'titel': 'Super Nintendo mit OVP',
          'kategorie': 'Konsole',
          'schaetzwert': 180.0,
          'zustand': 'Sammlerzustand',
          'standort_id': s1,
        });
        await db.insert('sammlungsstuecke', {
          'titel': 'Sony Walkman WM-DD',
          'kategorie': 'Audio',
          'schaetzwert': 320.0,
          'zustand': 'Gut',
          'standort_id': s3,
        });
      },
    );
  }

  static Future<List<Standort>> ladeStandorte() async {
    final db = await datenbank;
    final ergebnis = await db.query('standorte', orderBy: 'name ASC');
    return ergebnis.map((m) => Standort.fromMap(m)).toList();
  }

  static Future<List<Sammlungsstueck>> ladeAlleMitStandort() async {
    final db = await datenbank;
    final ergebnis = await db.rawQuery('''
      SELECT s.*, st.name as standort_name
      FROM sammlungsstuecke s
      LEFT JOIN standorte st ON s.standort_id = st.id
      ORDER BY s.titel ASC
    ''');
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

  static Future<void> wiederherstellen(Sammlungsstueck stueck) async {
    final db = await datenbank;
    // Explizit inklusive urspruenglicher ID wiederherstellen
    await db.insert('sammlungsstuecke', stueck.toMap());
  }
}
