import 'dart:math' as math;

class RadioAudioBlock {
  final List<double> samplesLinks;
  final List<double> samplesRechts;
  final double rmsLinks;
  final double rmsRechts;

  const RadioAudioBlock({
    required this.samplesLinks,
    required this.samplesRechts,
    required this.rmsLinks,
    required this.rmsRechts,
  });
}

class RadioSynthesizer {
  int _phaseTick = 0;

  // Erzeugt einen Block von Stereo-PCM-Samples (z. B. 882 Samples = 20 ms)
  RadioAudioBlock erzeugeBlock({
    int sampleCount = 882,
    double recLevel = 1.0,
  }) {
    final sL = List<double>.filled(sampleCount, 0.0);
    final sR = List<double>.filled(sampleCount, 0.0);

    double sumSqL = 0.0;
    double sumSqR = 0.0;

    // 80er-Jahre Synth-Akkordsequenz: Am - F - C - G
    final akkorde = [
      [220.0, 261.63, 329.63], // A-Moll (A3, C4, E4)
      [174.61, 220.0, 261.63], // F-Dur (F3, A3, C4)
      [130.81, 164.81, 196.0], // C-Dur (C3, E3, G3)
      [196.0, 246.94, 293.66], // G-Dur (G3, B3, D4)
    ];

    final takt = (_phaseTick ~/ 44100) % 4; // Wechselt jede Sekunde
    final freqs = akkorde[takt];

    for (int i = 0; i < sampleCount; i++) {
      final t = (_phaseTick + i) / 44100.0;

      // 3 Oszillatoren fuer den Akkord
      double waveL = 0.0;
      double waveR = 0.0;

      for (int k = 0; k < freqs.length; k++) {
        final f = freqs[k];
        // Saegezahn-aehnliche harmonische Mischung
        final osc = 0.5 * math.sin(2 * math.pi * f * t) +
            0.25 * math.sin(4 * math.pi * f * t);
        // Stereo-Panning (links/rechts leicht versetzt fuer Raumklang)
        waveL += osc * (k == 0 ? 0.7 : 0.5);
        waveR += osc * (k == 2 ? 0.7 : 0.5);
      }

      // Rhythmischer Beat (Bass-Pulse alle 0,5 Sekunden)
      final beatTime = t % 0.5;
      final kick = math.exp(-beatTime * 15.0) *
          math.sin(2 * math.pi * 65.0 * beatTime);
      waveL = (waveL * 0.4 + kick * 0.5) * recLevel;
      waveR = (waveR * 0.4 + kick * 0.5) * recLevel;

      sL[i] = waveL.clamp(-1.0, 1.0);
      sR[i] = waveR.clamp(-1.0, 1.0);

      sumSqL += sL[i] * sL[i];
      sumSqR += sR[i] * sR[i];
    }

    _phaseTick += sampleCount;

    final rmsL = math.sqrt(sumSqL / sampleCount);
    final rmsR = math.sqrt(sumSqR / sampleCount);

    return RadioAudioBlock(
      samplesLinks: sL,
      samplesRechts: sR,
      rmsLinks: rmsL,
      rmsRechts: rmsR,
    );
  }
}
