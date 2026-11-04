import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../app/shared/page_activity.dart';

import '../../services/tts/speech_synthesizer.dart';
import '../../services/tts/speech_synthesizer_factory.dart';

/// Interactive audio preview button allowing learners to listen to native pronunciation.
class AudioSamplePlayer extends StatefulWidget {
  const AudioSamplePlayer({
    super.key,
    required this.referenceText,
    this.sampleUri,
  });

  final String referenceText;
  final Uri? sampleUri;

  @override
  State<AudioSamplePlayer> createState() => _AudioSamplePlayerState();
}

class _AudioSamplePlayerState extends State<AudioSamplePlayer> {
  late final TextToSpeechPlayer _ttsPlayer;
  StreamSubscription<bool>? _playSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsPlayer = getPlatformTextToSpeechPlayer();
    _playSub = _ttsPlayer.isPlayingStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _ttsPlayer.stop();
      } else {
        await _ttsPlayer.speak(widget.referenceText, rate: 0.85);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không phát được mẫu. Kiểm tra âm lượng và giọng TTS tiếng Anh trên thiết bị.',
            ),
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!PageActivity.isActive(context) && _isPlaying) {
      unawaited(_ttsPlayer.stop());
    }
  }

  @override
  void didUpdateWidget(covariant AudioSamplePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceText != widget.referenceText && _isPlaying) {
      _ttsPlayer.stop();
    }
  }

  @override
  void dispose() {
    _playSub?.cancel();
    _ttsPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: _togglePlayback,
      icon: Icon(
        _isPlaying ? Icons.volume_up_rounded : Icons.volume_down_rounded,
        size: 20,
        color: _isPlaying ? theme.colorScheme.primary : null,
      ),
      label: Text(_isPlaying ? 'Đang phát âm mẫu…' : 'Nghe phát âm chuẩn'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
