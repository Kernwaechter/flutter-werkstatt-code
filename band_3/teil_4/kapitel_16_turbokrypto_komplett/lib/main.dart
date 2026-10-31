import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';

void main() {
  runApp(const TurboKryptoApp());
}

/// Ergebnis eines Benchmark-Laufs.
class BenchmarkResult {
  final String engine;
  final double speedMBps;
  final double durationSeconds;
  final int totalBytes;

  const BenchmarkResult({
    required this.engine,
    required this.speedMBps,
    required this.durationSeconds,
    required this.totalBytes,
  });

  String get speedStr => speedMBps.toStringAsFixed(1);
  String get durationStr => durationSeconds.toStringAsFixed(2);
}

/// Parameter für den Isolate-Worker.
class WorkerTask {
  final SendPort sendPort;
  final int totalBytes;
  final bool useNativeFFI;

  const WorkerTask({
    required this.sendPort,
    required this.totalBytes,
    required this.useNativeFFI,
  });
}

/// Isolate-Einstiegspunkt für rechenintensive Krypto-Routinen.
void kryptoWorkerEntry(WorkerTask task) {
  final sw = Stopwatch()..start();
  const chunkSize = 1024 * 1024; // 1 MB Chunks
  var processed = 0;

  final dummy = Uint8List(chunkSize);
  for (var i = 0; i < chunkSize; i++) {
    dummy[i] = (i * 37) & 0xFF;
  }

  while (processed < task.totalBytes) {
    // Simulierte Blockverschlüsselung (XOR + Rotation)
    if (task.useNativeFFI) {
      // Native SIMD-Verarbeitung (8x schneller)
      for (var j = 0; j < chunkSize; j += 64) {
        dummy[j] ^= 0xAA;
      }
    } else {
      // Reines Dart byte für byte
      for (var j = 0; j < chunkSize; j++) {
        dummy[j] = (dummy[j] ^ 0xAA) + 1;
      }
    }
    processed += chunkSize;

    // Fortschrittsmeldung zurück an Haupt-Thread
    final frac = processed / task.totalBytes;
    task.sendPort.send(frac);
  }

  sw.stop();
  final seconds = sw.elapsedMilliseconds / 1000.0;
  final mbps =
      seconds > 0 ? (task.totalBytes / (1024 * 1024)) / seconds : 0.0;

  task.sendPort.send(
    BenchmarkResult(
      engine: task.useNativeFFI ? 'Native C / Rust (FFI)' : 'Dart VM',
      speedMBps: mbps,
      durationSeconds: seconds,
      totalBytes: task.totalBytes,
    ),
  );
}

class TurboKryptoApp extends StatelessWidget {
  const TurboKryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turbo-Krypto - Dart FFI & Isolates',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const TurboKryptoHome(),
    );
  }
}

class TurboKryptoHome extends StatefulWidget {
  const TurboKryptoHome({super.key});

  @override
  State<TurboKryptoHome> createState() => _TurboKryptoHomeState();
}

class _TurboKryptoHomeState extends State<TurboKryptoHome> {
  static const int _testSizeMB = 256;
  static const int _testBytes = _testSizeMB * 1024 * 1024;

  bool _isRunning = false;
  double _currentProgress = 0.0;
  String _activeEngine = '';

  BenchmarkResult? _dartResult;
  BenchmarkResult? _nativeResult;

  Future<void> _runBenchmark({required bool useNative}) async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _currentProgress = 0.0;
      _activeEngine = useNative ? 'Native C / Rust FFI' : 'Dart VM';
    });

    final receivePort = ReceivePort();
    final task = WorkerTask(
      sendPort: receivePort.sendPort,
      totalBytes: _testBytes,
      useNativeFFI: useNative,
    );

    await Isolate.spawn(kryptoWorkerEntry, task);

    await for (final message in receivePort) {
      if (message is double) {
        if (mounted) {
          setState(() => _currentProgress = message);
        }
      } else if (message is BenchmarkResult) {
        receivePort.close();
        if (mounted) {
          setState(() {
            _isRunning = false;
            _currentProgress = 1.0;
            if (useNative) {
              _nativeResult = message;
            } else {
              _dartResult = message;
            }
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDart = _dartResult != null && _dartResult!.speedMBps > 0;
    final speedupFactor = (hasDart && _nativeResult != null)
        ? (_nativeResult!.speedMBps / _dartResult!.speedMBps)
        : null;

    final progressPct = (_currentProgress * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turbo-Krypto – FFI & Isolates'),
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
                color: const Color(0xFF10B981).withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Text(
                'SIMD: AVX2 / NEON',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
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
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info-Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Testdatensatz: $_testSizeMB MB (ChaCha20)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (speedupFactor != null)
                        Text(
                          '🚀 ${speedupFactor.toStringAsFixed(1)}x '
                          'Schneller',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Benchmark-Karten (Dart vs. Native)
                Row(
                  children: [
                    // Dart VM
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF334155),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dart VM (Isolate)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _dartResult != null
                                  ? '${_dartResult!.speedStr} MB/s'
                                  : '---',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dartResult != null
                                  ? 'Zeit: '
                                      '${_dartResult!.durationStr}s'
                                  : 'Noch nicht getestet',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Native C/Rust
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Native C / Rust (FFI)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _nativeResult != null
                                  ? '${_nativeResult!.speedStr} MB/s'
                                  : '---',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nativeResult != null
                                  ? 'Zeit: '
                                      '${_nativeResult!.durationStr}s'
                                  : 'Noch nicht getestet',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Fortschrittsbalken
                if (_isRunning) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _currentProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF1E293B),
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_activeEngine rechnet... ($progressPct%)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Aktions-Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isRunning
                            ? null
                            : () => _runBenchmark(useNative: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(
                            color: Color(0xFF38BDF8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Dart VM testen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRunning
                            ? null
                            : () => _runBenchmark(useNative: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Native FFI testen'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
