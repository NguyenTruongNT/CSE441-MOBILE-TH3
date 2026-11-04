import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../../../core/contracts/contracts.dart';
import '../../domain/audio_recorder.dart';

AudioRecorderController createPlatformAudioRecorder() => WebAudioRecorder();

class WebAudioRecorder implements AudioRecorderController {
  final _amplitudes = StreamController<double>.broadcast();
  final _states = StreamController<AudioRecorderState>.broadcast();
  final _clock = Stopwatch();
  final _chunks = <web.Blob>[];
  web.MediaStream? _stream;
  web.MediaRecorder? _recorder;
  web.AudioContext? _context;
  web.AnalyserNode? _analyser;
  Timer? _timer;
  Completer<AudioSample>? _pending;
  AudioRecorderState _state = AudioRecorderState.ready;
  bool _disposed = false;

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
  void _setState(AudioRecorderState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  Future<web.MediaStream> _openMicrophone() => web.window.navigator.mediaDevices
      .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
      .toDart;

  @override
  Future<bool> hasPermission() async => web.window.isSecureContext;

  @override
  Future<bool> requestPermission() async {
    try {
      final stream = await _openMicrophone();
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startRecording() async {
    if (isRecording || _disposed) return;
    try {
      _chunks.clear();
      _stream = await _openMicrophone();
      if (_disposed) {
        await _release();
        return;
      }
      _context = web.AudioContext();
      _analyser = _context!.createAnalyser()..fftSize = 256;
      _context!.createMediaStreamSource(_stream!).connect(_analyser!);
      final mime = [
        'audio/webm;codecs=opus',
        'audio/webm',
        'audio/ogg;codecs=opus',
        'audio/mp4',
      ].where((mime) => web.MediaRecorder.isTypeSupported(mime)).firstOrNull;
      _recorder = mime == null
          ? web.MediaRecorder(_stream!)
          : web.MediaRecorder(
              _stream!,
              web.MediaRecorderOptions(mimeType: mime),
            );
      _recorder!.ondataavailable = ((web.BlobEvent event) {
        if (event.data.size > 0) _chunks.add(event.data);
      }).toJS;
      _recorder!.onstop = ((web.Event event) {
        unawaited(_complete());
      }).toJS;
      _recorder!.onerror = ((web.Event event) {
        final pending = _pending;
        if (pending != null && !pending.isCompleted) {
          pending.completeError(
            const AppFailure(
              AppFailureCode.invalidAudio,
              'Trình duyệt không hoàn tất được bản ghi.',
            ),
          );
        }
        unawaited(_release());
        _setState(AudioRecorderState.error);
      }).toJS;
      _recorder!.start(100);
      _clock
        ..reset()
        ..start();
      _setState(AudioRecorderState.recording);
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!isRecording || _analyser == null) return;
        final samples = Uint8List(256);
        _analyser!.getByteTimeDomainData(samples.toJS);
        var sum = 0.0;
        for (final sample in samples) {
          final value = (sample - 128) / 128;
          sum += value * value;
        }
        if (!_amplitudes.isClosed) {
          _amplitudes.add((math.sqrt(sum / samples.length) * 4).clamp(0, 1));
        }
      });
    } catch (_) {
      await _release();
      _setState(AudioRecorderState.error);
      throw const AppFailure(
        AppFailureCode.permissionDenied,
        'Không mở được micro. Hãy cấp quyền và dùng localhost hoặc HTTPS.',
      );
    }
  }

  @override
  Future<AudioSample> stopRecording() {
    if (!isRecording || _recorder == null) {
      return Future.error(
        const AppFailure(AppFailureCode.invalidAudio, 'Chưa có bản ghi âm.'),
      );
    }
    _clock.stop();
    _timer?.cancel();
    _setState(AudioRecorderState.processing);
    _pending = Completer<AudioSample>();
    _recorder!.stop();
    return _pending!.future;
  }

  Future<void> _complete() async {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    try {
      final mime = _recorder!.mimeType;
      final blob = web.Blob(_chunks.toJS, web.BlobPropertyBag(type: mime));
      final buffer = (await blob.arrayBuffer().toDart).toDart;
      if (!pending.isCompleted) {
        pending.complete(
          AudioSample(bytes: Uint8List.view(buffer), mimeType: mime),
        );
      }
    } catch (_) {
      if (!pending.isCompleted) {
        pending.completeError(
          const AppFailure(
            AppFailureCode.invalidAudio,
            'Không đọc được dữ liệu âm thanh.',
          ),
        );
      }
    } finally {
      await _release();
      _setState(AudioRecorderState.ready);
    }
  }

  Future<void> _release() async {
    _timer?.cancel();
    _clock.stop();
    for (final track
        in _stream?.getTracks().toDart ?? <web.MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
    final context = _context;
    _context = null;
    _analyser = null;
    if (context != null && context.state != 'closed') {
      await context.close().toDart;
    }
  }

  @override
  Future<void> cancelRecording() async {
    final recorder = _recorder;
    if (recorder != null) {
      recorder.onstop = null;
      if (recorder.state != 'inactive') recorder.stop();
    }
    await _release();
    _chunks.clear();
    _setState(AudioRecorderState.ready);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancelRecording());
    unawaited(_amplitudes.close());
    unawaited(_states.close());
  }
}
