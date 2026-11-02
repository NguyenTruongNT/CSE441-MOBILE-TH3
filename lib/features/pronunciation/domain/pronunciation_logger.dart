import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, debug }

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.tag,
    required this.message,
    this.level = LogLevel.info,
    this.details,
  });

  final DateTime timestamp;
  final String tag;
  final String message;
  final LogLevel level;
  final String? details;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = (timestamp.millisecond ~/ 100).toString();
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() => '[$formattedTime] [$tag] $message${details != null ? ' ($details)' : ''}';
}

/// Centralized logger for pronunciation audio, STT recognition, and scoring.
class PronunciationLogger {
  PronunciationLogger._();

  static final List<LogEntry> _history = [];
  static final _logStreamController = StreamController<LogEntry>.broadcast();

  static List<LogEntry> get history => List.unmodifiable(_history);
  static Stream<LogEntry> get stream => _logStreamController.stream;

  static void info(String tag, String message, [String? details]) {
    _log(LogLevel.info, tag, message, details);
  }

  static void warn(String tag, String message, [String? details]) {
    _log(LogLevel.warning, tag, '⚠️ $message', details);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stack]) {
    final errStr = error?.toString();
    _log(LogLevel.error, tag, '❌ $message', errStr);
    if (stack != null && kDebugMode) {
      debugPrint('[PronunciationAI:Stack] $stack');
    }
  }

  static void stt(String message, [String? details]) {
    _log(LogLevel.info, 'STT', '🗣️ $message', details);
  }

  static void audio(String message, [String? details]) {
    _log(LogLevel.info, 'AUDIO', '🎙️ $message', details);
  }

  static void scoring(String message, [String? details]) {
    _log(LogLevel.info, 'SCORING', '📊 $message', details);
  }

  static void _log(LogLevel level, String tag, String message, String? details) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      level: level,
      details: details,
    );

    _history.add(entry);
    if (_history.length > 200) {
      _history.removeAt(0);
    }

    _logStreamController.add(entry);
    // Only output to terminal when an error occurs
    if (level == LogLevel.error) {
      debugPrint('[PronunciationAI:ERROR] ${entry.toString()}');
    }
  }

  static void clear() {
    _history.clear();
  }
}
