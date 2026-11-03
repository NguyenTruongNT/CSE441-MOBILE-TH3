import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';

import '../domain/audio_validator.dart';
import 'http/http_client.dart';

/// Real API service communicating with the pronunciation backend proxy
/// or standard cloud speech assessment endpoints.
class RemotePronunciationService implements PronunciationService {
  RemotePronunciationService({
    Uri? endpoint,
    this.apiKey,
    HttpTransport? transport,
    AudioValidator? validator,
    this.timeout = const Duration(seconds: 120),
  }) : endpoint =
           endpoint ??
           Uri.parse(
             const String.fromEnvironment(
                       'PRONUNCIATION_API_URL',
                       defaultValue: '',
                     ) !=
                     ''
                 ? const String.fromEnvironment('PRONUNCIATION_API_URL')
                 : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
                       ? 'http://10.0.2.2:8080/api/pronounce/analyze'
                       : 'http://127.0.0.1:8080/api/pronounce/analyze'),
           ),
       _transport = transport ?? getHttpTransport(),
       _validator = validator ?? const AudioValidator();

  final Uri endpoint;
  final String? apiKey;
  final HttpTransport _transport;
  final AudioValidator _validator;
  final Duration timeout;
  String? clientTranscript;

  @override
  Future<PronunciationResult> analyze({
    required String sessionId,
    required AudioSample audio,
    required Exercise exercise,
  }) async {
    // 1. Client-side audio check
    _validator.validate(audio);

    // 2. Prepare payload
    final payload = {
      'sessionId': sessionId,
      'exerciseId': exercise.id,
      'referenceText': exercise.referenceText,
      'referenceIpa': exercise.referenceIpa,
      'targetPhonemes': exercise.targetPhonemes,
      'audioBase64': base64Encode(audio.bytes),
      'mimeType': audio.mimeType,
      'clientTranscript': clientTranscript ?? '',
    };

    final headers = <String, String>{'Accept': 'application/json'};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    try {
      final response = await _transport.postJson(
        uri: endpoint,
        headers: headers,
        jsonBody: jsonEncode(payload),
        timeout: timeout,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseResultJson(data, sessionId, exercise);
      } else {
        // Map HTTP error code to typed AppFailure
        return _handleHttpErrorResponse(response);
      }
    } on TimeoutException {
      throw const AppFailure(
        AppFailureCode.timeout,
        'Phân tích mất quá nhiều thời gian. Kiểm tra backend rồi thử lại.',
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure(
        AppFailureCode.network,
        'Không thể kết nối đến máy chủ AI ($endpoint): $e',
      );
    }
  }

  Never _handleHttpErrorResponse(HttpResponseData response) {
    var errorMsg = 'Lỗi máy chủ (${response.statusCode})';
    var code = AppFailureCode.unknown;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json.containsKey('message')) {
        errorMsg = json['message'].toString();
      }
      if (json.containsKey('code')) {
        final codeStr = json['code'].toString();
        code = AppFailureCode.values.firstWhere(
          (c) => c.name == codeStr,
          orElse: () => AppFailureCode.unknown,
        );
      }
    } catch (_) {}

    if (response.statusCode == 400 && code == AppFailureCode.unknown) {
      code = AppFailureCode.invalidAudio;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      code = AppFailureCode.permissionDenied;
    } else if (response.statusCode == 408 || response.statusCode == 504) {
      code = AppFailureCode.timeout;
    }

    throw AppFailure(code, errorMsg);
  }

  PronunciationResult _parseResultJson(
    Map<String, dynamic> json,
    String sessionId,
    Exercise exercise,
  ) {
    if (json['sessionId'] != sessionId ||
        json['recognizedText'] is! String ||
        (json['recognizedText'] as String).trim().isEmpty ||
        json['phonemes'] is! List ||
        (json['phonemes'] as List).isEmpty) {
      throw const AppFailure(
        AppFailureCode.insufficientEvidence,
        'Backend chưa cung cấp đủ kết quả nhận dạng và âm vị.',
      );
    }
    final overall = (json['overallScore'] as num).toDouble();
    final rawPhonemes = (json['phonemes'] as List?) ?? [];

    final phonemes = rawPhonemes.map((item) {
      final m = item as Map<String, dynamic>;
      final statusStr = m['status'] as String? ?? 'notAssessed';
      final status = PhonemeStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => PhonemeStatus.notAssessed,
      );

      final scoreNum = m['score'] as num?;
      return PhonemeFeedback(
        word: m['word'] as String? ?? '',
        expectedIpa: m['expectedIpa'] as String? ?? '',
        recognizedIpa: m['recognizedIpa'] as String?,
        score: scoreNum?.toDouble(),
        status: status,
        startMilliseconds: m['startMilliseconds'] as int?,
        endMilliseconds: m['endMilliseconds'] as int?,
        suggestion: m['suggestion'] as String? ?? '',
      );
    }).toList();

    return PronunciationResult(
      id: json['id'] as String? ?? 'res-$sessionId',
      sessionId: sessionId,
      referenceText: json['referenceText'] as String? ?? exercise.referenceText,
      recognizedText: json['recognizedText'] as String,
      overallScore: overall,
      provider: json['provider'] as String? ?? 'remote-ai-proxy',
      modelVersion: json['modelVersion'] as String? ?? 'v1.0.0',
      analyzedAt: json.containsKey('analyzedAt')
          ? DateTime.parse(json['analyzedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      phonemes: phonemes,
    );
  }
}
