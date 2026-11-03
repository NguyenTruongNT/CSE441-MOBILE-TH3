import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../../../core/contracts/contracts.dart';
import '../../domain/audio_recorder.dart';

AudioRecorderController createPlatformAudioRecorder() => MobileAudioRecorder();

class MobileAudioRecorder implements AudioRecorderController {
  final _native = AudioRecorder();
  final _clock = Stopwatch();
  final _states = StreamController<AudioRecorderState>.broadcast();
  final _amplitudes = StreamController<double>.broadcast();
  final _bytes = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  AudioRecorderState _state = AudioRecorderState.ready;
  @override
  AudioRecorderState get state => _state;
  @override
  bool get isRecording => _state == AudioRecorderState.recording;
  @override
  int get elapsedMilliseconds => _clock.elapsedMilliseconds;
  @override
  Stream<double> get amplitudeStream => _amplitudes.stream;
  @override
  Stream<AudioRecorderState> get stateStream => _states.stream;
  @override
  Future<bool> hasPermission() => _native.hasPermission(request: false);
  @override
  Future<bool> requestPermission() => _native.hasPermission();
  void _setState(AudioRecorderState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  @override
  Future<void> startRecording() async {
    if (isRecording) return;
    if (!await requestPermission()) {
      throw const AppFailure(
        AppFailureCode.permissionDenied,
        'Chưa có quyền micro.',
      );
    }
    _bytes.clear();
    try {
      final stream = await _native.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _audioSubscription = stream.listen(_bytes.add);
      _amplitudeSubscription = _native
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
            if (!_amplitudes.isClosed) {
              _amplitudes.add(((amp.current + 60) / 60).clamp(0, 1));
            }
          });
      _clock
        ..reset()
        ..start();
      _setState(AudioRecorderState.recording);
    } catch (_) {
      _setState(AudioRecorderState.error);
      throw const AppFailure(
        AppFailureCode.invalidAudio,
        'Không mở được micro. Hãy đóng ứng dụng đang dùng micro rồi thử lại.',
      );
    }
  }

  @override
  Future<AudioSample> stopRecording() async {
    if (!isRecording) {
      throw const AppFailure(
        AppFailureCode.invalidAudio,
        'Chưa có bản ghi âm.',
      );
    }
    _clock.stop();
    await _native.stop();
    await _audioSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    final pcm = _bytes.takeBytes();
    final wav = Uint8List(44 + pcm.length);
    final header = ByteData.sublistView(wav);
    wav.setRange(0, 4, 'RIFF'.codeUnits);
    header.setUint32(4, 36 + pcm.length, Endian.little);
    wav.setRange(8, 16, 'WAVEfmt '.codeUnits);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, 16000, Endian.little);
    header.setUint32(28, 32000, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    wav.setRange(36, 40, 'data'.codeUnits);
    header.setUint32(40, pcm.length, Endian.little);
    wav.setRange(44, wav.length, pcm);
    _setState(AudioRecorderState.ready);
    return AudioSample(bytes: wav, mimeType: 'audio/wav');
  }

  @override
  Future<void> cancelRecording() async {
    _clock.stop();
    await _native.cancel();
    await _audioSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    _bytes.clear();
    _setState(AudioRecorderState.ready);
  }

  @override
  void dispose() {
    _clock.stop();
    unawaited(_audioSubscription?.cancel());
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_native.dispose());
    unawaited(_states.close());
    unawaited(_amplitudes.close());
  }
}
