import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SharedLibraryApp());
}

// C-Signaturen:
typedef NativeCrc32 = ffi.Uint32 Function(
  ffi.Pointer<ffi.Uint8> data,
  ffi.Size length,
);
typedef DartCrc32 = int Function(
  ffi.Pointer<ffi.Uint8> data,
  int length,
);

typedef NativeXor = ffi.Void Function(
  ffi.Pointer<ffi.Uint8> out,
  ffi.Pointer<ffi.Uint8> inData,
  ffi.Size length,
  ffi.Pointer<ffi.Uint8> key,
);
typedef DartXor = void Function(
  ffi.Pointer<ffi.Uint8> out,
  ffi.Pointer<ffi.Uint8> inData,
  int length,
  ffi.Pointer<ffi.Uint8> key,
);

class TurboKryptoBindings {
  static DartCrc32? _crc32;
  static DartXor? _xorEncrypt;
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static void init() {
    try {
      final libPath = _findLibrary();
      final dylib = ffi.DynamicLibrary.open(libPath);

      _crc32 = dylib.lookupFunction<NativeCrc32, DartCrc32>(
        'fast_crc32',
      );
      _xorEncrypt = dylib.lookupFunction<NativeXor, DartXor>(
        'chacha20_xor',
      );
      _loaded = true;
    } catch (e) {
      debugPrint('Hinweis: Native Bibliothek nicht geladen: $e');
      _loaded = false;
    }
  }

  static String _findLibrary() {
    // 1. Suche im aktuellen Arbeitsverzeichnis
    if (Platform.isLinux &&
        File('./libturbokrypto.so').existsSync()) {
      return './libturbokrypto.so';
    }
    if (Platform.isMacOS &&
        File('./libturbokrypto.dylib').existsSync()) {
      return './libturbokrypto.dylib';
    }
    if (Platform.isWindows && File('turbokrypto.dll').existsSync()) {
      return 'turbokrypto.dll';
    }

    // 2. Suche relativ zum Programm-Pfad
    final dir = File(Platform.resolvedExecutable).parent.path;
    return '$dir/libturbokrypto.so';
  }

  /// Führt native XOR-Verschlüsselung per FFI aus.
  static Uint8List encrypt(Uint8List plain, Uint8List key32) {
    if (_xorEncrypt != null) {
      final pIn = calloc<ffi.Uint8>(plain.length);
      final pOut = calloc<ffi.Uint8>(plain.length);
      final pKey = calloc<ffi.Uint8>(32);

      try {
        pIn.asTypedList(plain.length).setAll(0, plain);
        final safeKey = key32.length >= 32
            ? key32.sublist(0, 32)
            : key32.followedBy(List.filled(32 - key32.length, 0));
        pKey.asTypedList(32).setAll(0, safeKey);

        _xorEncrypt!(pOut, pIn, plain.length, pKey);
        return Uint8List.fromList(pOut.asTypedList(plain.length));
      } finally {
        calloc.free(pIn);
        calloc.free(pOut);
        calloc.free(pKey);
      }
    }

    // Fallback: Reines Dart
    final out = Uint8List(plain.length);
    for (var i = 0; i < plain.length; i++) {
      out[i] = plain[i] ^ key32[i % 32];
    }
    return out;
  }

  /// Berechnet die CRC32-Prüfsumme per FFI.
  static int crc32(Uint8List data) {
    if (_crc32 != null && data.isNotEmpty) {
      final ptr = calloc<ffi.Uint8>(data.length);
      try {
        ptr.asTypedList(data.length).setAll(0, data);
        return _crc32!(ptr, data.length);
      } finally {
        calloc.free(ptr);
      }
    }
    return 0;
  }
}

class SharedLibraryApp extends StatelessWidget {
  const SharedLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Shared Libraries',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const SharedLibraryHome(),
    );
  }
}

class SharedLibraryHome extends StatefulWidget {
  const SharedLibraryHome({super.key});

  @override
  State<SharedLibraryHome> createState() => _SharedLibraryHomeState();
}

class _SharedLibraryHomeState extends State<SharedLibraryHome> {
  final _textController = TextEditingController(
    text: 'Geheimer Werkstatt-Plan: Drehbank auf 1400 U/min!',
  );
  Uint8List? _encrypted;
  String? _decrypted;

  // 32-Byte Demo-Schlüssel
  final Uint8List _key = Uint8List.fromList(
    utf8.encode('Werkbank-Secret-Key-32-Bytes!!'),
  );

  @override
  void initState() {
    super.initState();
    TurboKryptoBindings.init();
    _runEncryption();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _runEncryption() {
    final plainBytes = Uint8List.fromList(
      utf8.encode(_textController.text),
    );
    final enc = TurboKryptoBindings.encrypt(plainBytes, _key);
    final dec = TurboKryptoBindings.encrypt(enc, _key);

    setState(() {
      _encrypted = enc;
      _decrypted = utf8.decode(dec, allowMalformed: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = TurboKryptoBindings.isLoaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Shared Libraries (.so/.dylib)'),
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
                color: isLoaded
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFE11D48).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLoaded
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE11D48),
                ),
              ),
              child: Text(
                isLoaded ? 'Native .so Geladen' : 'Dart Fallback',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isLoaded
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE11D48),
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
            constraints: const BoxConstraints(maxWidth: 540),
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
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.extension_rounded,
                            color: Color(0xFF10B981),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'C/Rust Shared Library',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'C-ABI Maschinencode-Ausführung',
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
                      'Klartext-Eingabe:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _textController,
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
                      onChanged: (_) => _runEncryption(),
                    ),
                    const SizedBox(height: 16),
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
                            'Chiffrat (Hex-Dump aus C-Puffer):',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            _encrypted != null
                                ? _encrypted!
                                    .map((b) => b
                                        .toRadixString(16)
                                        .padLeft(2, '0'))
                                    .join(' ')
                                : '---',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const Divider(
                            height: 20,
                            color: Color(0xFF334155),
                          ),
                          const Text(
                            'Rückentschlüsselter Klartext:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _decrypted ?? '---',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
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
