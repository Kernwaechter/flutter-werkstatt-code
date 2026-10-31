class SensorDaten {
  final double x;
  final double y;
  final double z;
  final DateTime zeitstempel;

  const SensorDaten({
    required this.x,
    required this.y,
    required this.z,
    required this.zeitstempel,
  });

  bool get istAusgerichtet {
    return x.abs() <= 0.5 && y.abs() <= 0.5;
  }

  SensorDaten copyWith({
    double? x,
    double? y,
    double? z,
    DateTime? zeitstempel,
  }) {
    return SensorDaten(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      zeitstempel: zeitstempel ?? this.zeitstempel,
    );
  }
}
