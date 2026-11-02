import '../../domain/audio_recorder.dart';
import 'web_audio_recorder_stub.dart'
    if (dart.library.html) 'web_audio_recorder.dart'
    if (dart.library.io) 'mobile_audio_recorder.dart';

AudioRecorderController getPlatformAudioRecorder() => createPlatformAudioRecorder();

