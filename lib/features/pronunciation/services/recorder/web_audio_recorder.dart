// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';
import '../../domain/audio_recorder.dart';

class WebAudioRecorder implements AudioRecorderController {
  WebAudioRecorder();

  AudioRecorderState _state = AudioRecorderState.ready;
  final _amplitudeController = StreamController<double>.broadcast();
  final _stateController = StreamController<AudioRecorderState>.broadcast();

  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _chunks = [];
  Timer? _ampTimer;
  int _elapsedMs = 0;
  DateTime? _startTime;

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

  void _setState(AudioRecorderState s) {
    _state = s;
    _stateController.add(s);
  }

  @override
  Future<bool> hasPermission() async {
    return html.window.navigator.mediaDevices != null;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      stream?.getTracks().forEach((track) => track.stop());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startRecording() async {
    try {
      _chunks.clear();
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      if (_mediaStream == null) {
        throw const AppFailure(
          AppFailureCode.permissionDenied,
          'Không thể kết nối đến micro trên trình duyệt web.',
        );
      }

      _mediaRecorder = html.MediaRecorder(_mediaStream!);
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final dataEvent = event as html.BlobEvent;
        if (dataEvent.data != null && (dataEvent.data!.size > 0)) {
          _chunks.add(dataEvent.data!);
        }
      });

      _mediaRecorder!.start(100);
      _startTime = DateTime.now();
      _elapsedMs = 0;
      _setState(AudioRecorderState.recording);

      _ampTimer?.cancel();
      _ampTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!isRecording) return;
        _elapsedMs = DateTime.now().difference(_startTime!).inMilliseconds;
        // Visual fluctuation
        _amplitudeController.add(0.3 + 0.3 * (t.tick % 5) / 5.0);
      });
    } catch (e) {
      _setState(AudioRecorderState.error);
      throw AppFailure(
        AppFailureCode.permissionDenied,
        'Trình duyệt chưa được cấp quyền micro: $e',
      );
    }
  }

  @override
  Future<AudioSample> stopRecording() async {
    if (!isRecording || _mediaRecorder == null) {
      throw const AppFailure(AppFailureCode.invalidAudio, 'Chưa ở trạng thái ghi âm');
    }

    _ampTimer?.cancel();
    _setState(AudioRecorderState.processing);

    final completer = Completer<AudioSample>();

    _mediaRecorder!.addEventListener('stop', (event) async {
      try {
        final blob = html.Blob(_chunks, 'audio/webm');
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is Uint8List) {
            completer.complete(AudioSample(bytes: result, mimeType: 'audio/webm'));
          } else if (result is ByteBuffer) {
            completer.complete(AudioSample(bytes: Uint8List.view(result), mimeType: 'audio/webm'));
          } else {
            completer.completeError(
              const AppFailure(AppFailureCode.invalidAudio, 'Không thể đọc dữ liệu âm thanh từ trình duyệt'),
            );
          }
        });
      } catch (e) {
        completer.completeError(
          AppFailure(AppFailureCode.invalidAudio, 'Lỗi xử lý file âm thanh: $e'),
        );
      } finally {
        _mediaStream?.getTracks().forEach((track) => track.stop());
        _setState(AudioRecorderState.ready);
      }
    });

    _mediaRecorder!.stop();
    return completer.future;
  }

  @override
  Future<void> cancelRecording() async {
    _ampTimer?.cancel();
    _mediaRecorder?.stop();
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _chunks.clear();
    _setState(AudioRecorderState.ready);
  }

  @override
  void dispose() {
    _ampTimer?.cancel();
    _mediaRecorder?.stop();
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _amplitudeController.close();
    _stateController.close();
  }
}

AudioRecorderController createPlatformAudioRecorder() => WebAudioRecorder();
