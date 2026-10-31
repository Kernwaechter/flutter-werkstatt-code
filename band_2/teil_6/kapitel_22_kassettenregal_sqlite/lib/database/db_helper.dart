import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/kassette.dart';

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

    final pfad = join(await getDatabasesPath(), 'kassetten_regal.db');

    return await openDatabase(
      pfad,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kassetten (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titel TEXT NOT NULL,
            bandtyp TEXT NOT NULL,
            farbcode INTEGER NOT NULL,
            wav_pfad TEXT NOT NULL,
            dauer_sekunden INTEGER NOT NULL
          )
        ''');

        // Drei Standard-Mixtapes beim ersten Start anlegen
        await db.insert('kassetten', {
          'titel': 'Synthwave 86 Classics',
          'bandtyp': 'CrO2 II',
          'farbcode': 0xFFB45309,
          'wav_pfad': 'synthwave_86.wav',
          'dauer_sekunden': 240,
        });
        await db.insert('kassetten', {
          'titel': 'Sonntags-Hitparade Radio',
          'bandtyp': 'Fe I',
          'farbcode': 0xFF1E293B,
          'wav_pfad': 'hitparade.wav',
          'dauer_sekunden': 180,
        });
        await db.insert('kassetten', {
          'titel': 'Metal Mastertape Live',
          'bandtyp': 'Metal IV',
          'farbcode': 0xFFBE185D,
          'wav_pfad': 'metal_live.wav',
          'dauer_sekunden': 310,
        });
      },
    );
  }

  static Future<List<Kassette>> ladeRegal() async {
    final db = await datenbank;
    final ergebnis = await db.query('kassetten', orderBy: 'id ASC');
    return ergebnis.map((m) => Kassette.fromMap(m)).toList();
  }

  static Future<int> hinzufuegen(Kassette k) async {
    final db = await datenbank;
    return await db.insert('kassetten', k.toMap());
  }

  static Future<int> loeschen(int id) async {
    final db = await datenbank;
    return await db.delete('kassetten', where: 'id = ?', whereArgs: [id]);
  }
}
