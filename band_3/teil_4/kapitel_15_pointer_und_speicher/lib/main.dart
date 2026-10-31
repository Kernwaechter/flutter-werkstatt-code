import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const NativeMemoryApp());
}

/// C-Struktur für einen Krypto-Paket-Header im nativen Speicher.
/// Repräsentiert exakt das C-Layout:
/// struct KryptoHeader {
///     uint32_t magic;
///     uint16_t version;
///     uint16_t algorithmId;
///     uint64_t payloadLength;
/// };
final class KryptoHeaderStruct extends ffi.Struct {
  @ffi.Uint32()
  external int magic;

  @ffi.Uint16()
  external int version;

  @ffi.Uint16()
  external int algorithmId;

  @ffi.Uint64()
  external int payloadLength;
}

/// Verwaltet Allokationen und überwacht Speicherlecks.
class NativeMemoryTracker {
  static int _allocatedBytes = 0;
  static int _activePointers = 0;

  static int get allocatedBytes => _allocatedBytes;
  static int get activePointers => _activePointers;

  /// Allokiert einen Header auf dem C-Heap.
  static ffi.Pointer<KryptoHeaderStruct> allocateHeader({
    required int magic,
    required int version,
    required int algorithmId,
    required int payloadLength,
  }) {
    final ptr = calloc<KryptoHeaderStruct>();
    ptr.ref.magic = magic;
    ptr.ref.version = version;
    ptr.ref.algorithmId = algorithmId;
    ptr.ref.payloadLength = payloadLength;

    _allocatedBytes += ffi.sizeOf<KryptoHeaderStruct>();
    _activePointers++;
    return ptr;
  }

  /// Gibt den nativen Speicher frei.
  static void freeHeader(ffi.Pointer<KryptoHeaderStruct> ptr) {
    if (ptr.address != 0) {
      calloc.free(ptr);
      _allocatedBytes -= ffi.sizeOf<KryptoHeaderStruct>();
      _activePointers--;
    }
  }
}

class NativeMemoryApp extends StatelessWidget {
  const NativeMemoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pointer & native Structs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const NativeMemoryHome(),
    );
  }
}

class NativeMemoryHome extends StatefulWidget {
  const NativeMemoryHome({super.key});

  @override
  State<NativeMemoryHome> createState() => _NativeMemoryHomeState();
}

class _NativeMemoryHomeState extends State<NativeMemoryHome> {
  final List<ffi.Pointer<KryptoHeaderStruct>> _allocatedList = [];
  String _logMessage =
      'Bereit für native Allokationen auf dem C-Heap.';

  void _allocateNewHeader() {
    final ptr = NativeMemoryTracker.allocateHeader(
      magic: 0x57424450, // 'WBDP'
      version: 1,
      algorithmId: 256, // ChaCha20
      payloadLength: 1024 * 1024 * 64, // 64 MB
    );

    setState(() {
      _allocatedList.add(ptr);
      _logMessage =
          'Allokiert: Header an 0x${ptr.address.toRadixString(16)} '
          '(${ffi.sizeOf<KryptoHeaderStruct>()} Bytes)';
    });
  }

  void _freeLastHeader() {
    if (_allocatedList.isEmpty) return;

    final ptr = _allocatedList.removeLast();
    final addr = ptr.address.toRadixString(16);
    NativeMemoryTracker.freeHeader(ptr);

    setState(() {
      _logMessage = 'Freigegeben: calloc.free(0x$addr) erfolgreich.';
    });
  }

  void _freeAll() {
    while (_allocatedList.isNotEmpty) {
      final ptr = _allocatedList.removeLast();
      NativeMemoryTracker.freeHeader(ptr);
    }
    setState(() {
      _logMessage =
          'Alle nativen Speicherbereiche sauber freigegeben!';
    });
  }

  @override
  void dispose() {
    _freeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = NativeMemoryTracker.activePointers;
    final totalBytes = NativeMemoryTracker.allocatedBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointer & Structs (C-Heap)'),
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
                color: activeCount == 0
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeCount == 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF38BDF8),
                ),
              ),
              child: Text(
                'Leaks: 0 Bytes (Aktiv: $activeCount)',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: activeCount == 0
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
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nativer Speicher-Monitor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Heap-Verwaltung (calloc / free)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF334155),
                            ),
                          ),
                          child: Text(
                            '$totalBytes Bytes',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'C-Struktur Definition (16 Bytes):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'struct KryptoHeader {\n'
                            '  uint32_t magic;          // 4B\n'
                            '  uint16_t version;        // 2B\n'
                            '  uint16_t algorithmId;    // 2B\n'
                            '  uint64_t payloadLength;  // 8B\n'
                            '};',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF38BDF8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _logMessage,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _allocateNewHeader,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('calloc()'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _allocatedList.isNotEmpty
                                ? _freeLastHeader
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFFE11D48),
                              side: const BorderSide(
                                color: Color(0xFFE11D48),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.remove_rounded),
                            label: const Text('free()'),
                          ),
                        ),
                      ],
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
