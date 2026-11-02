import 'dart:math' as math;
import 'dart:typed_data';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';

/// Audio validation rules to reject corrupted, silent, or insufficient recordings
/// before triggering costly or invalid API assessments.
class AudioValidationResult {
  const AudioValidationResult({
    required this.isValid,
    required this.rmsEnergy,
    required this.durationEstimateSeconds,
    this.failure,
  });

  final bool isValid;
  final double rmsEnergy;
  final double durationEstimateSeconds;
  final AppFailure? failure;
}

class AudioValidator {
  const AudioValidator({
    this.minDurationSeconds = 0.4,
    this.maxDurationSeconds = 60.0,
    this.minRmsSilenceThreshold = 0.008,
  });

  final double minDurationSeconds;
  final double maxDurationSeconds;
  final double minRmsSilenceThreshold;

  /// Inspects an [AudioSample] and throws [AppFailure] if audio is not assessable.
  AudioValidationResult validate(AudioSample audio) {
    if (audio.bytes.isEmpty) {
      throw const AppFailure(
        AppFailureCode.invalidAudio,
        'Dữ liệu âm thanh trống.',
      );
    }

    final mime = audio.mimeType.toLowerCase();
    final validMimes = [
      'audio/wav',
      'audio/x-wav',
      'audio/webm',
      'audio/ogg',
      'audio/mp4',
      'audio/aac',
      'audio/m4a',
      'audio/pcm',
    ];

    if (!validMimes.any((m) => mime.contains(m))) {
      throw AppFailure(
        AppFailureCode.invalidAudio,
        'Định dạng âm thanh "$mime" không được hỗ trợ. Cần WAV, WebM hoặc AAC.',
      );
    }

    // Inspect byte payload and calculate signal energy
    final energy = calculateRmsEnergy(audio.bytes, mime);
    final durationSec = estimateDurationSeconds(audio.bytes, mime);

    if (durationSec < minDurationSeconds) {
      throw AppFailure(
        AppFailureCode.insufficientEvidence,
        'Bản ghi quá ngắn (${(durationSec * 1000).toInt()}ms). '
        'Vui lòng phát âm trọn vẹn câu trước khi dừng.',
      );
    }

    if (durationSec > maxDurationSeconds) {
      throw AppFailure(
        AppFailureCode.invalidAudio,
        'Bản ghi quá dài (${durationSec.toStringAsFixed(1)}s). '
        'Mỗi câu luyện tập không nên vượt quá 60 giây.',
      );
    }

    // Pure silence check
    if (energy < minRmsSilenceThreshold) {
      throw const AppFailure(
        AppFailureCode.insufficientEvidence,
        'Không phát hiện tín hiệu giọng nói (âm lượng quá nhỏ hoặc micro bị tắt tiếng). '
        'Vui lòng nói gần micro hơn và thử lại.',
      );
    }

    return AudioValidationResult(
      isValid: true,
      rmsEnergy: energy,
      durationEstimateSeconds: durationSec,
    );
  }

  /// Calculates Root Mean Square (RMS) energy normalized to [0.0..1.0].
  static double calculateRmsEnergy(Uint8List bytes, String mime) {
    if (bytes.length < 64) return 0.0;

    // If WAV PCM format, skip 44-byte header and parse 16-bit little-endian samples
    var offset = 0;
    if (bytes.length > 44 &&
        bytes[0] == 0x52 && // 'R'
        bytes[1] == 0x49 && // 'I'
        bytes[2] == 0x46 && // 'F'
        bytes[3] == 0x46) {
      offset = 44;
    }

    var sumSquares = 0.0;
    var sampleCount = 0;

    // Read 16-bit PCM samples
    final byteData = ByteData.sublistView(bytes);
    final maxSamplesToCheck = math.min(byteData.lengthInBytes - 1, 8000);

    for (var i = offset; i < maxSamplesToCheck; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      final normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
      sampleCount++;
    }

    if (sampleCount == 0) return 0.0;
    final rms = math.sqrt(sumSquares / sampleCount);
    return rms.clamp(0.0, 1.0);
  }

  /// Estimates duration from audio headers or byte length.
  static double estimateDurationSeconds(Uint8List bytes, String mime) {
    if (bytes.length > 44 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      // Parse sample rate and byte rate from standard RIFF WAV header
      final byteData = ByteData.sublistView(bytes);
      final byteRate = byteData.getUint32(28, Endian.little);
      final dataSize = bytes.length - 44;
      if (byteRate > 0) {
        return (dataSize / byteRate).clamp(0.0, 600.0);
      }
    }

    // Default heuristic: 16kHz mono 16-bit PCM is 32,000 bytes per second
    // Compressed WebM/Opus is typically ~4,000 bytes/sec at 32kbps
    if (mime.contains('webm') || mime.contains('ogg') || mime.contains('aac')) {
      return (bytes.length / 4000.0).clamp(0.1, 120.0);
    }
    return (bytes.length / 32000.0).clamp(0.1, 120.0);
  }
}
