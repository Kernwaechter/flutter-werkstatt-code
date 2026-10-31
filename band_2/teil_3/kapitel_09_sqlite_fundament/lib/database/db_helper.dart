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
    // Fuer Desktop (Linux, Windows, macOS) FFI aktivieren
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final pfad = join(await getDatabasesPath(), 'sammlung_kap09.db');

    return await openDatabase(
      pfad,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sammlungsstuecke (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titel TEXT NOT NULL,
            kategorie TEXT NOT NULL,
            schaetzwert REAL NOT NULL
          )
        ''');
      },
    );
  }

  static Future<int> einfuegen(Sammlungsstueck stueck) async {
    final db = await datenbank;
    return await db.insert('sammlungsstuecke', stueck.toMap());
  }

  static Future<List<Sammlungsstueck>> alleLesen() async {
    final db = await datenbank;
    final ergebnis = await db.query('sammlungsstuecke');
    return ergebnis.map((m) => Sammlungsstueck.fromMap(m)).toList();
  }
}
