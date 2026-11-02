import 'dart:math' as math;
import 'dart:typed_data';
import 'package:th3_english_ai/core/contracts/models.dart';

/// Utilities to generate standard PCM WAV byte buffers in memory for tests,
/// automated verification, and offline speech simulation.
class AudioSampleFixtures {
  AudioSampleFixtures._();

  /// Generates a valid 16-bit mono RIFF WAV audio sample.
  static AudioSample createWavSample({
    double durationSeconds = 2.0,
    int sampleRate = 16000,
    double frequencyHz = 300.0,
    double volume = 0.4,
  }) {
    final numSamples = (durationSeconds * sampleRate).toInt();
    final byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    buffer.setUint16(22, 1, Endian.little); // NumChannels (1 mono)
    buffer.setUint32(24, sampleRate, Endian.little); // SampleRate
    buffer.setUint32(28, byteRate, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little); // BlockAlign (2 bytes)
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // data subchunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Synthesize realistic speech-like waveform (fundamental + harmonic modulation)
    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final wave = math.sin(2 * math.pi * frequencyHz * t) * 0.7 +
          math.sin(2 * math.pi * (frequencyHz * 2.2) * t) * 0.3;
      final envelope = math.sin(math.pi * (i / numSamples)); // attack & release
      final sampleVal = (wave * envelope * volume * 32767).toInt().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sampleVal, Endian.little);
    }

    return AudioSample(
      bytes: buffer.buffer.asUint8List(),
      mimeType: 'audio/wav',
    );
  }

  /// Generates a silent WAV sample with zero amplitude.
  static AudioSample createSilentWavSample({double durationSeconds = 1.5}) {
    return createWavSample(
      durationSeconds: durationSeconds,
      volume: 0.0001,
    );
  }

  /// Generates an audio sample that is too short (< 0.4s).
  static AudioSample createTooShortWavSample() {
    return createWavSample(durationSeconds: 0.2);
  }
}
