import '../../domain/audio_recorder.dart';
import '../audio_recorder_service.dart';

AudioRecorderController createPlatformAudioRecorder() => SimulatedAudioRecorder();
