/// Shared data contracts, version 1. All persisted timestamps use UTC.
library;

import 'dart:typed_data';

enum PracticeStatus { completed, cancelled, analysisFailed }

enum PhonemeStatus { correct, needsPractice, notAssessed }

class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    required DateTime createdAt,
    this.timeZone = 'Asia/Ho_Chi_Minh',
  }) : createdAt = createdAt.toUtc();

  final String id;
  final String displayName;
  final String timeZone;
  final DateTime createdAt;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.referenceText,
    required this.referenceIpa,
    required this.targetPhonemes,
    this.sampleAudioUri,
  });

  final String id;
  final String referenceText;
  final String referenceIpa;
  final List<String> targetPhonemes;
  final Uri? sampleAudioUri;
}

class PracticeSession {
  PracticeSession({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required DateTime startedAt,
    required DateTime endedAt,
    required this.durationSeconds,
    required this.status,
  }) : startedAt = startedAt.toUtc(),
       endedAt = endedAt.toUtc() {
    if (durationSeconds < 0 || endedAt.isBefore(startedAt)) {
      throw ArgumentError('Invalid practice duration or time range.');
    }
  }

  final String id;
  final String userId;
  final String exerciseId;
  final DateTime startedAt;
  final DateTime endedAt;
  // Active practice only: exclude idle time and API latency.
  final int durationSeconds;
  final PracticeStatus status;
}

class PhonemeFeedback {
  PhonemeFeedback({
    required this.word,
    required this.expectedIpa,
    required this.status,
    required this.suggestion,
    this.recognizedIpa,
    this.score,
    this.startMilliseconds,
    this.endMilliseconds,
  }) {
    if (score != null) _validateScore(score!);
    if ((startMilliseconds == null) != (endMilliseconds == null) ||
        (startMilliseconds != null &&
            (startMilliseconds! < 0 ||
                endMilliseconds! < startMilliseconds!))) {
      throw ArgumentError('Phoneme timestamps must form a valid pair.');
    }
  }

  final String word;
  final String expectedIpa;
  final String? recognizedIpa;
  final double? score;
  final PhonemeStatus status;
  final int? startMilliseconds;
  final int? endMilliseconds;
  final String suggestion;
}

class PronunciationResult {
  PronunciationResult({
    required this.id,
    required this.sessionId,
    required this.referenceText,
    required this.recognizedText,
    required this.overallScore,
    required this.provider,
    required this.modelVersion,
    required DateTime analyzedAt,
    required List<PhonemeFeedback> phonemes,
  }) : analyzedAt = analyzedAt.toUtc(),
       phonemes = List.unmodifiable(phonemes) {
    _validateScore(overallScore);
  }

  final String id;
  final String sessionId;
  final String referenceText;
  final String recognizedText;
  final double overallScore;
  final String provider;
  final String modelVersion;
  final DateTime analyzedAt;
  final List<PhonemeFeedback> phonemes;
}

class LearningSettings {
  LearningSettings({
    required this.userId,
    this.dailyGoalMinutes = 15,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.timeZone = 'Asia/Ho_Chi_Minh',
  }) {
    if (dailyGoalMinutes <= 0 ||
        reminderHour < 0 ||
        reminderHour > 23 ||
        reminderMinute < 0 ||
        reminderMinute > 59) {
      throw ArgumentError('Invalid daily goal or reminder time.');
    }
  }

  final String userId;
  final int dailyGoalMinutes;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final String timeZone;
}

class AudioSample {
  AudioSample({required Uint8List bytes, required this.mimeType})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView() {
    if (bytes.isEmpty || mimeType.isEmpty) {
      throw ArgumentError('Audio bytes and MIME type are required.');
    }
  }

  final Uint8List bytes;
  final String mimeType;
}

void _validateScore(double value) {
  if (!value.isFinite || value < 0 || value > 100) {
    throw ArgumentError.value(value, 'score', 'Must be finite and in 0..100.');
  }
}
