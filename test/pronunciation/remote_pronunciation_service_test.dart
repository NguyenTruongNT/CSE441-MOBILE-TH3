import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';
import 'package:th3_english_ai/features/pronunciation/data/audio_sample_fixtures.dart';
import 'package:th3_english_ai/features/pronunciation/data/default_exercises.dart';
import 'package:th3_english_ai/features/pronunciation/services/http/http_transport.dart';
import 'package:th3_english_ai/features/pronunciation/services/remote_pronunciation_service.dart';

class MockHttpTransport implements HttpTransport {
  MockHttpTransport({
    this.responseStatusCode = 200,
    this.responseBody = '{}',
    this.throwException,
  });

  int responseStatusCode;
  String responseBody;
  Exception? throwException;

  @override
  Future<HttpResponseData> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String jsonBody,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (throwException != null) {
      throw throwException!;
    }
    return HttpResponseData(
      statusCode: responseStatusCode,
      body: responseBody,
    );
  }
}

void main() {
  final exercise = DefaultExercises.catalog.first.exercise;
  final validAudio = AudioSampleFixtures.createWavSample(durationSeconds: 1.5);

  test('RemotePronunciationService parses valid backend response', () async {
    final mockJson = jsonEncode({
      'id': 'res-123',
      'sessionId': 'sess-123',
      'referenceText': 'I think this method is great',
      'recognizedText': 'I think this method is great',
      'overallScore': 88.5,
      'provider': 'speech-backend',
      'modelVersion': 'v1.0',
      'phonemes': [
        {
          'word': 'think',
          'expectedIpa': 'θ',
          'recognizedIpa': 'θ',
          'score': 90.0,
          'status': 'correct',
          'startMilliseconds': 100,
          'endMilliseconds': 250,
          'suggestion': 'Phát âm tốt âm /θ/.',
        }
      ]
    });

    final transport = MockHttpTransport(
      responseStatusCode: 200,
      responseBody: mockJson,
    );

    final service = RemotePronunciationService(
      transport: transport,
      enableLocalFallbackWhenUnreachable: false,
    );

    final result = await service.analyze(
      sessionId: 'sess-123',
      audio: validAudio,
      exercise: exercise,
    );

    expect(result.id, 'res-123');
    expect(result.overallScore, 88.5);
    expect(result.phonemes.length, 1);
    expect(result.phonemes.first.status, PhonemeStatus.correct);
  });

  test('RemotePronunciationService maps 400 error to invalidAudio', () async {
    final transport = MockHttpTransport(
      responseStatusCode: 400,
      responseBody: jsonEncode({'message': 'Audio corrupted', 'code': 'invalidAudio'}),
    );

    final service = RemotePronunciationService(
      transport: transport,
      enableLocalFallbackWhenUnreachable: false,
    );

    expect(
      () => service.analyze(
        sessionId: 'sess-err',
        audio: validAudio,
        exercise: exercise,
      ),
      throwsA(
        isA<AppFailure>().having((e) => e.code, 'code', AppFailureCode.invalidAudio),
      ),
    );
  });

  test('RemotePronunciationService falls back to local engine when server is unreachable', () async {
    final transport = MockHttpTransport(
      throwException: const FormatException('Connection refused'),
    );

    final service = RemotePronunciationService(
      transport: transport,
      enableLocalFallbackWhenUnreachable: true,
    );

    final result = await service.analyze(
      sessionId: 'sess-fallback',
      audio: validAudio,
      exercise: exercise,
    );

    expect(result.sessionId, 'sess-fallback');
    expect(result.overallScore, inInclusiveRange(0.0, 100.0));
  });
}
