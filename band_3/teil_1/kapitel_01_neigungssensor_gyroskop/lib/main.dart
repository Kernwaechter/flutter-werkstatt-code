import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const SensorApp());
}

class SensorApp extends StatelessWidget {
  const SensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neigung & Gyroskop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SensorMonitorScreen(),
    );
  }
}

class SensorMonitorScreen extends StatefulWidget {
  const SensorMonitorScreen({super.key});

  @override
  State<SensorMonitorScreen> createState() =>
      _SensorMonitorScreenState();
}

class _SensorMonitorScreenState extends State<SensorMonitorScreen> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 9.81;

  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  double _pitch = 0.0;
  double _roll = 0.0;

  double _pitchOffset = 0.0;
  double _rollOffset = 0.0;

  int _eventCount = 0;
  int _sampleRateHz = 0;
  Timer? _rateTimer;

  bool _isHardwareSensorActive = false;

  @override
  void initState() {
    super.initState();
    _startListening();
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sampleRateHz = _eventCount;
          _eventCount = 0;
        });
      }
    });
  }

  void _startListening() {
    try {
      _accelSub = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (!mounted) return;
          setState(() {
            _isHardwareSensorActive = true;
            _accelX = event.x;
            _accelY = event.y;
            _accelZ = event.z;
            _updateAngles();
            _eventCount++;
          });
        },
        onError: (dynamic error) {
          debugPrint('Beschleunigungssensor nicht verfügbar: $error');
        },
      );

      _gyroSub = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          if (!mounted) return;
          setState(() {
            _gyroX = event.x;
            _gyroY = event.y;
            _gyroZ = event.z;
          });
        },
        onError: (dynamic error) {
          debugPrint('Gyroskop nicht verfügbar: $error');
        },
      );
    } catch (e) {
      debugPrint('Sensor-Initialisierung fehlgeschlagen: $e');
    }
  }

  void _updateAngles() {
    final double norm = math.sqrt(
      _accelX * _accelX + _accelZ * _accelZ,
    );
    final double rawPitch =
        math.atan2(_accelY, norm) * (180.0 / math.pi);
    final double rawRoll =
        math.atan2(-_accelX, _accelZ) * (180.0 / math.pi);

    _pitch = rawPitch - _pitchOffset;
    _roll = rawRoll - _rollOffset;
  }

  void _calibrate() {
    final double norm = math.sqrt(
      _accelX * _accelX + _accelZ * _accelZ,
    );
    final double rawPitch =
        math.atan2(_accelY, norm) * (180.0 / math.pi);
    final double rawRoll =
        math.atan2(-_accelX, _accelZ) * (180.0 / math.pi);

    setState(() {
      _pitchOffset = rawPitch;
      _rollOffset = rawRoll;
      _updateAngles();
    });
  }

  void _resetCalibration() {
    setState(() {
      _pitchOffset = 0.0;
      _rollOffset = 0.0;
      _updateAngles();
    });
  }

  void _simulateMovement(Offset localPos, Size boxSize) {
    if (_isHardwareSensorActive) return;
    final double relX = (localPos.dx / boxSize.width) * 2.0 - 1.0;
    final double relY = (localPos.dy / boxSize.height) * 2.0 - 1.0;

    setState(() {
      _accelX = -relX * 8.0;
      _accelY = relY * 8.0;
      final double zSqr =
          (9.81 * 9.81) - (_accelX * _accelX + _accelY * _accelY);
      _accelZ = zSqr > 0 ? math.sqrt(zSqr) : 1.0;
      _gyroX = relY * 2.0;
      _gyroY = -relX * 2.0;
      _updateAngles();
      _eventCount++;
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _rateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181B),
      appBar: AppBar(
        title: const Text('Sensor-Monitor: Achsen & Winkel'),
        backgroundColor: const Color(0xFF1E272C),
        actions: [
          IconButton(
            tooltip: 'Kalibrieren (Nullpunkt)',
            icon: const Icon(Icons.tune),
            onPressed: _calibrate,
          ),
          IconButton(
            tooltip: 'Kalibrierung zurücksetzen',
            icon: const Icon(Icons.refresh),
            onPressed: _resetCalibration,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 16),
                  _buildSimulatorPad(constraints.maxWidth),
                  const SizedBox(height: 16),
                  _buildAngleCards(),
                  const SizedBox(height: 16),
                  _buildRawDataCard('Beschleunigung (m/s²)', [
                    'X: ${_accelX.toStringAsFixed(3)} m/s²',
                    'Y: ${_accelY.toStringAsFixed(3)} m/s²',
                    'Z: ${_accelZ.toStringAsFixed(3)} m/s²',
                    'Betrag: '
                    '${_vectorLength().toStringAsFixed(2)} m/s²',
                  ]),
                  const SizedBox(height: 16),
                  _buildRawDataCard('Gyroskop / Drehrate (rad/s)', [
                    'ωX: ${_gyroX.toStringAsFixed(3)} rad/s',
                    'ωY: ${_gyroY.toStringAsFixed(3)} rad/s',
                    'ωZ: ${_gyroZ.toStringAsFixed(3)} rad/s',
                    'Frequenz: $_sampleRateHz Hz',
                  ]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _vectorLength() {
    return math.sqrt(
      _accelX * _accelX + _accelY * _accelY + _accelZ * _accelZ,
    );
  }

  Widget _buildStatusBanner() {
    final bool calibrated = _pitchOffset != 0.0 || _rollOffset != 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: _isHardwareSensorActive
            ? const Color(0xFF1B5E20).withValues(alpha: 0.35)
            : const Color(0xFFE65100).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHardwareSensorActive
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF9800),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isHardwareSensorActive
                ? Icons.sensors
                : Icons.touch_app_outlined,
            color: _isHardwareSensorActive
                ? const Color(0xFF81C784)
                : const Color(0xFFFFB74D),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isHardwareSensorActive
                  ? 'Hardware-Sensoren aktiv ($_sampleRateHz Hz)'
                  : 'Desktop-Modus: Touch/Maus-Simulation aktiv',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (calibrated)
            const Chip(
              label: Text(
                'Kalibriert',
                style: TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildSimulatorPad(double maxWidth) {
    final double boxSize = math.min(maxWidth - 32, 220.0);
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          _simulateMovement(
            details.localPosition,
            Size(boxSize, boxSize),
          );
        },
        child: Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: const Color(0xFF1E272C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF37474F),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                child: Text(
                  'Sensor-Pad\n(Ziehen zum Neigen)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),
              Align(
                alignment: Alignment(
                  (_accelX / 9.81).clamp(-1.0, 1.0),
                  (_accelY / 9.81).clamp(-1.0, 1.0),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x6600E676),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAngleCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Neigung (Pitch)',
            value: '${_pitch.toStringAsFixed(1)}°',
            sub: 'Vorne / Hinten',
            color: const Color(0xFF00B0FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Rollwinkel (Roll)',
            value: '${_roll.toStringAsFixed(1)}°',
            sub: 'Links / Rechts',
            color: const Color(0xFF76FF03),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard(String heading, List<String> entries) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF80CBC4),
            ),
          ),
          const Divider(height: 20, color: Color(0xFF2E3C43)),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                e,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

