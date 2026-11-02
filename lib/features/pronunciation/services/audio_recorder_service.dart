import 'dart:async';
import 'dart:math' as math;
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';
import '../data/audio_sample_fixtures.dart';
import '../domain/audio_recorder.dart';

/// Configurable audio recorder supporting both simulated speech capture
/// (for testing, desktop, and preview) and real platform integration.
class SimulatedAudioRecorder implements AudioRecorderController {
  SimulatedAudioRecorder({
    bool initialPermissionGranted = true,
    this.simulatedDurationSeconds = 2.5,
    this.simulatedAudioSample,
    this.failOnStart = false,
  }) : _hasPermission = initialPermissionGranted;

  bool _hasPermission;
  final double simulatedDurationSeconds;
  final AudioSample? simulatedAudioSample;
  final bool failOnStart;

  AudioRecorderState _state = AudioRecorderState.ready;
  final _amplitudeController = StreamController<double>.broadcast();
  final _stateController = StreamController<AudioRecorderState>.broadcast();

  Timer? _timer;
  int _elapsedMs = 0;
  final _random = math.Random();

  @override
  AudioRecorderState get state => _state;

  @override
  bool get isRecording => _state == AudioRecorderState.recording;

  @override
  int get elapsedMilliseconds => _elapsedMs;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Stream<AudioRecorderState> get stateStream => _stateController.stream;

  void _setState(AudioRecorderState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<bool> hasPermission() async => _hasPermission;

  @override
  Future<bool> requestPermission() async {
    _hasPermission = true;
    _setState(AudioRecorderState.ready);
    return true;
  }

  void revokePermissionForTesting() {
    _hasPermission = false;
    _setState(AudioRecorderState.uninitialized);
  }

  @override
  Future<void> startRecording() async {
    if (!_hasPermission) {
      throw const AppFailure(
        AppFailureCode.permissionDenied,
        'Quyền truy cập micro đã bị từ chối. Vui lòng cấp quyền trong cài đặt thiết bị.',
      );
    }

    if (failOnStart) {
      _setState(AudioRecorderState.error);
      throw const AppFailure(
        AppFailureCode.invalidAudio,
        'Không thể mở thiết bị thu âm.',
      );
    }

    _elapsedMs = 0;
    _setState(AudioRecorderState.recording);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!isRecording) return;
      _elapsedMs += 100;

      // Generate natural fluctuating speech amplitude [0.15 .. 0.85]
      final base = 0.4 + 0.3 * math.sin(_elapsedMs / 250);
      final jitter = (_random.nextDouble() - 0.5) * 0.2;
      final amp = (base + jitter).clamp(0.05, 1.0);
      _amplitudeController.add(amp);
    });
  }

  @override
  Future<AudioSample> stopRecording() async {
    if (!isRecording) {
      throw const AppFailure(
        AppFailureCode.invalidAudio,
        'Thiết bị chưa ở trạng thái ghi âm.',
      );
    }

    _timer?.cancel();
    _setState(AudioRecorderState.processing);

    final durationSec = math.max(0.5, _elapsedMs / 1000.0);
    _setState(AudioRecorderState.ready);

    return simulatedAudioSample ??
        AudioSampleFixtures.createWavSample(
          durationSeconds: durationSec,
          frequencyHz: 280.0,
          volume: 0.5,
        );
  }

  @override
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _elapsedMs = 0;
    _amplitudeController.add(0.0);
    _setState(AudioRecorderState.ready);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeController.close();
    _stateController.close();
  }
}
