import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class WavRecorder {
  RandomAccessFile? _file;
  int _gesammelteBytes = 0;
  String? _dateipfad;

  bool get nimmtAuf => _file != null;
  String? get dateipfad => _dateipfad;
  int get aufgenommeneBytes => _gesammelteBytes;

  static const int sampleRate = 44100;
  static const int kanaele = 2; // Stereo
  static const int bitsProSample = 16;

  Future<String> starteAufnahme({String dateiname = 'aufnahme_1986.wav'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final zielPfad = join(dir.path, dateiname);
    _dateipfad = zielPfad;
    _gesammelteBytes = 0;

    final datei = File(zielPfad);
    if (await datei.exists()) {
      await datei.delete();
    }

    _file = await datei.open(mode: FileMode.write);

    // 44-Byte WAV-Header vorbereiten (Platzhalter fuer Dateigroesse)
    final header = Uint8List(44);
    final byteData = ByteData.sublistView(header);

    // "RIFF"
    header.setRange(0, 4, 'RIFF'.codeUnits);
    // ChunkSize (Platzhalter bei Offset 4, wird am Ende geschrieben)
    byteData.setUint32(4, 36, Endian.little);
    // "WAVE"
    header.setRange(8, 12, 'WAVE'.codeUnits);
    // "fmt "
    header.setRange(12, 16, 'fmt '.codeUnits);
    // Subchunk1Size (16 fuer PCM)
    byteData.setUint32(16, 16, Endian.little);
    // AudioFormat (1 fuer PCM)
    byteData.setUint16(20, 1, Endian.little);
    // NumChannels (2 fuer Stereo)
    byteData.setUint16(22, kanaele, Endian.little);
    // SampleRate (44100 Hz)
    byteData.setUint32(24, sampleRate, Endian.little);
    // ByteRate = SampleRate * NumChannels * BitsPerSample / 8
    const byteRate = sampleRate * kanaele * (bitsProSample ~/ 8);
    byteData.setUint32(28, byteRate, Endian.little);
    // BlockAlign = NumChannels * BitsPerSample / 8
    const blockAlign = kanaele * (bitsProSample ~/ 8);
    byteData.setUint16(32, blockAlign, Endian.little);
    // BitsPerSample
    byteData.setUint16(34, bitsProSample, Endian.little);
    // "data"
    header.setRange(36, 40, 'data'.codeUnits);
    // Subchunk2Size (Platzhalter bei Offset 40)
    byteData.setUint32(40, 0, Endian.little);

    await _file!.writeFrom(header);
    return zielPfad;
  }

  // Schreibt Stereo 16-Bit PCM Samples (Wertebereich -1.0 bis +1.0)
  Future<void> schreibeSamples(List<double> links, List<double> rechts) async {
    if (_file == null) return;
    final anzahl = links.length;
    final buffer = Uint8List(anzahl * 4); // 2 Kanaele * 2 Bytes
    final byteData = ByteData.sublistView(buffer);

    for (int i = 0; i < anzahl; i++) {
      final sL = (links[i].clamp(-1.0, 1.0) * 32767.0).toInt();
      final sR = (rechts[i].clamp(-1.0, 1.0) * 32767.0).toInt();

      byteData.setInt16(i * 4, sL, Endian.little);
      byteData.setInt16(i * 4 + 2, sR, Endian.little);
    }

    await _file!.writeFrom(buffer);
    _gesammelteBytes += buffer.length;
  }

  Future<String> beendeAufnahme() async {
    if (_file == null) throw Exception('Keine aktive Aufnahme!');

    // Groessen im Header nachtraeglich aktualisieren
    final headerUpdate = ByteData(4);

    // 1. ChunkSize bei Offset 4: 36 + dataSize
    headerUpdate.setUint32(0, 36 + _gesammelteBytes, Endian.little);
    await _file!.setPosition(4);
    await _file!.writeFrom(headerUpdate.buffer.asUint8List());

    // 2. Subchunk2Size bei Offset 40: dataSize
    headerUpdate.setUint32(0, _gesammelteBytes, Endian.little);
    await _file!.setPosition(40);
    await _file!.writeFrom(headerUpdate.buffer.asUint8List());

    await _file!.close();
    _file = null;

    return _dateipfad!;
  }
}
