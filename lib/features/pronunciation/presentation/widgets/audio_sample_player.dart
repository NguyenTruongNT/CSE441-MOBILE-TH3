import 'dart:async';
import 'package:flutter/material.dart';

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
  bool _isPlaying = false;
  Timer? _playbackTimer;

  void _togglePlayback() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      // Simulate playback time (1.8s) for the reference text
      _playbackTimer?.cancel();
      _playbackTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
