import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FfiBridgeApp());
}

// C-Funktionssignaturen für FFI:
// uint32_t fast_crc32(const uint8_t* data, size_t length);
typedef NativeCrc32 = ffi.Uint32 Function(
  ffi.Pointer<ffi.Uint8> data,
  ffi.Size length,
);
typedef DartCrc32 = int Function(
  ffi.Pointer<ffi.Uint8> data,
  int length,
);

/// Brücke zur nativen C-Bibliothek mit automatischem Fallback.
class NativeCryptoBridge {
  static DartCrc32? _nativeCrc32;
  static bool _isNativeLoaded = false;

  static bool get isNativeLoaded => _isNativeLoaded;

  /// Versucht, die native Bibliothek zu laden.
  static void initialize() {
    try {
      final libraryPath = _getLibraryPath();
      final dylib = ffi.DynamicLibrary.open(libraryPath);
      _nativeCrc32 = dylib.lookupFunction<NativeCrc32, DartCrc32>(
        'fast_crc32',
      );
      _isNativeLoaded = true;
    } catch (_) {
      // Fallback auf reinen Dart-Algorithmus
      _isNativeLoaded = false;
    }
  }

  static String _getLibraryPath() {
    if (Platform.isLinux) return './libturbokrypto.so';
    if (Platform.isMacOS) return './libturbokrypto.dylib';
    if (Platform.isWindows) return 'turbokrypto.dll';
    return 'libturbokrypto.so';
  }

  /// Berechnet die CRC32-Prüfsumme.
  static int calculateCrc32(Uint8List data) {
    // 1. Wenn native C-Funktion verfügbar: Direkter FFI-Aufruf
    if (_nativeCrc32 != null && data.isNotEmpty) {
      final ptr = calloc<ffi.Uint8>(data.length);
      try {
        ptr.asTypedList(data.length).setAll(0, data);
        return _nativeCrc32!(ptr, data.length);
      } finally {
        calloc.free(ptr);
      }
    }

    // 2. Zuverlässiger reiner Dart-Algorithmus (IEEE 802.3)
    var crc = 0xFFFFFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

class FfiBridgeApp extends StatelessWidget {
  const FfiBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dart:ffi Brücke',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const FfiBridgeHome(),
    );
  }
}

class FfiBridgeHome extends StatefulWidget {
  const FfiBridgeHome({super.key});

  @override
  State<FfiBridgeHome> createState() => _FfiBridgeHomeState();
}

class _FfiBridgeHomeState extends State<FfiBridgeHome> {
  final _inputController = TextEditingController(
    text: 'Die Flutter- und Dart-Werkstatt – Band 3: FFI Turbo!',
  );
  int? _crc32Result;
  double _elapsedMicroseconds = 0.0;

  String get _crc32Hex {
    if (_crc32Result == null) return '---';
    final hex = _crc32Result!.toRadixString(16).toUpperCase();
    return '0x${hex.padLeft(8, '0')}';
  }

  String get _timeUs =>
      '${_elapsedMicroseconds.toStringAsFixed(1)} µs';

  @override
  void initState() {
    super.initState();
    NativeCryptoBridge.initialize();
    _computeChecksum();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _computeChecksum() {
    final text = _inputController.text;
    final bytes = Uint8List.fromList(utf8.encode(text));

    final sw = Stopwatch()..start();
    final result = NativeCryptoBridge.calculateCrc32(bytes);
    sw.stop();

    setState(() {
      _crc32Result = result;
      _elapsedMicroseconds = sw.elapsedMicroseconds.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNative = NativeCryptoBridge.isNativeLoaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('dart:ffi – Native C-Brücke'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isNative
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isNative
                      ? const Color(0xFF10B981)
                      : const Color(0xFF38BDF8),
                ),
              ),
              child: Text(
                isNative ? 'C-ABI Aktiv (.so)' : 'Dart Engine (AOT)',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isNative
                      ? const Color(0xFF10B981)
                      : const Color(0xFF38BDF8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48).withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.memory_rounded,
                            color: Color(0xFFE11D48),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Native FFI-Prüfsumme',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'IEEE 802.3 CRC32 Prüfsummen-Engine',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Zu prüfender Eingabetext:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _inputController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      onChanged: (_) => _computeChecksum(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CRC32 Prüfsumme (Hex / Dezimal):',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _crc32Hex,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              Text(
                                _timeUs,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _computeChecksum,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Prüfsumme neu berechnen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
