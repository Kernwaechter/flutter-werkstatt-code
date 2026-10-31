import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropPipelineApp());
}

/// Datenmodell für eine Datei in der Übertragungswarteschlange.
class QueueFile {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  int processedBytes;
  String? sha256Hash;
  bool isCompleted;

  QueueFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    this.processedBytes = 0,
    this.sha256Hash,
    this.isCompleted = false,
  });

  double get fraction =>
      sizeBytes > 0 ? processedBytes / sizeBytes : 0.0;
  String get sizeMB =>
      (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
}

class DropPipelineApp extends StatelessWidget {
  const DropPipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag & Drop Datei-Pipeline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D48),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const DropPipelineHome(),
    );
  }
}

class DropPipelineHome extends StatefulWidget {
  const DropPipelineHome({super.key});

  @override
  State<DropPipelineHome> createState() => _DropPipelineHomeState();
}

class _DropPipelineHomeState extends State<DropPipelineHome> {
  final List<QueueFile> _queue = [];
  bool _isDraggingOver = false;
  bool _isProcessing = false;

  void _addSampleFiles() {
    setState(() {
      _queue.addAll([
        QueueFile(
          id: '1',
          name: 'werkstatt_plan_cad.dxf',
          sizeBytes: 14 * 1024 * 1024, // 14 MB
          mimeType: 'application/dxf',
        ),
        QueueFile(
          id: '2',
          name: 'backup_datenbank.sqlite',
          sizeBytes: 32 * 1024 * 1024, // 32 MB
          mimeType: 'application/vnd.sqlite3',
        ),
        QueueFile(
          id: '3',
          name: 'sensordaten_export.csv',
          sizeBytes: 4 * 1024 * 1024, // 4 MB
          mimeType: 'text/csv',
        ),
      ]);
    });
  }

  /// Verarbeitet die Warteschlange über eine Stream-Pipeline,
  /// berechnet kontinuierlich die SHA-256 Prüfsumme in 64-KB Chunks.
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    setState(() => _isProcessing = true);

    for (final item in _queue) {
      if (item.isCompleted) continue;

      const chunkSize = 64 * 1024;
      var processed = 0;
      var accumulator = <int>[];

      while (processed < item.sizeBytes) {
        await Future.delayed(const Duration(milliseconds: 10));
        processed += chunkSize;
        if (processed > item.sizeBytes) processed = item.sizeBytes;

        accumulator = sha256
            .convert(utf8.encode('chunk-$processed'))
            .bytes;

        if (!mounted) return;
        setState(() {
          item.processedBytes = processed;
        });
      }

      final hashHex = accumulator
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      if (!mounted) return;
      setState(() {
        item.isCompleted = true;
        item.sha256Hash = hashHex.substring(0, 16);
      });
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  void _clearQueue() {
    setState(() => _queue.clear());
  }

  @override
  Widget build(BuildContext context) {
    final totalBytes = _queue.fold<int>(
      0,
      (sum, f) => sum + f.sizeBytes,
    );
    final processedBytes = _queue.fold<int>(
      0,
      (sum, f) => sum + f.processedBytes,
    );
    final totalFraction =
        totalBytes > 0 ? processedBytes / totalBytes : 0.0;
    final pct = (totalFraction * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkbank-Drop – Pipeline'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          if (_queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Warteschlange leeren',
              onPressed: _isProcessing ? null : _clearQueue,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Drag & Drop Dropzone
            DragTarget<String>(
              onWillAcceptWithDetails: (_) {
                setState(() => _isDraggingOver = true);
                return true;
              },
              onLeave: (_) {
                setState(() => _isDraggingOver = false);
              },
              onAcceptWithDetails: (_) {
                setState(() => _isDraggingOver = false);
                _addSampleFiles();
              },
              builder: (context, candidateData, rejectedData) {
                return InkWell(
                  onTap: _addSampleFiles,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isDraggingOver
                          ? const Color(0xFF38BDF8).withValues(
                              alpha: 0.12,
                            )
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDraggingOver
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF334155),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isDraggingOver
                              ? Icons.file_download_rounded
                              : Icons.cloud_upload_outlined,
                          size: 44,
                          color: _isDraggingOver
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Dateien per Drag & Drop hierher ziehen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'oder anklicken für Beispieldateien',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Gesamt-Fortschritt
            if (_queue.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fortschritt (${_queue.length} Dateien)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalFraction,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF0F172A),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Dateiliste
            Expanded(
              child: _queue.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Dateien in der Warteschlange',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _queue.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final file = _queue[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: file.isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    file.isCompleted
                                        ? Icons.verified_rounded
                                        : Icons.description_rounded,
                                    size: 20,
                                    color: file.isCompleted
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF38BDF8),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${file.sizeMB} MB',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: file.fraction,
                                minHeight: 4,
                                backgroundColor:
                                    const Color(0xFF0F172A),
                                color: file.isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF38BDF8),
                              ),
                              if (file.sha256Hash != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'SHA-256: ${file.sha256Hash}...',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _queue.isNotEmpty && !_isProcessing
          ? FloatingActionButton.extended(
              onPressed: _processQueue,
              backgroundColor: const Color(0xFFE11D48),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Stream-Pipeline starten'),
            )
          : null,
    );
  }
}
