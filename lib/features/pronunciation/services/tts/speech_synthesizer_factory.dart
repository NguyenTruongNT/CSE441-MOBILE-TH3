import 'speech_synthesizer.dart';
import 'stub_speech_synthesizer.dart'
    if (dart.library.html) 'web_speech_synthesizer.dart';

TextToSpeechPlayer getPlatformTextToSpeechPlayer() =>
    createTextToSpeechPlayer();
