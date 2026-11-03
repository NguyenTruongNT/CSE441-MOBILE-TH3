// ignore_for_file: deprecated_member_use
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Real-time animated audio waveform reacting to microphone amplitude changes.
class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    required this.amplitudeStream,
    required this.isRecording,
    this.barCount = 28,
    this.height = 70,
  });

  final Stream<double> amplitudeStream;
  final bool isRecording;
  final int barCount;
  final double height;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> {
  late final List<double> _bars;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _bars = List.generate(widget.barCount, (_) => 0.15);
    widget.amplitudeStream.listen(_onAmplitude);
  }

  void _onAmplitude(double amp) {
    if (!mounted || !widget.isRecording) return;
    setState(() {
      _bars.removeAt(0);
      // Generate varied bar heights from the incoming amplitude
      final jitter = (_random.nextDouble() - 0.5) * 0.2;
      final val = (amp + jitter).clamp(0.08, 1.0);
      _bars.add(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          final barHeight = widget.isRecording
              ? (_bars[i] * (widget.height - 16)).clamp(6.0, widget.height - 16)
              : 6.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 4,
            height: barHeight,
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? primary.withOpacity((0.4 + _bars[i] * 0.6).clamp(0.4, 1.0))
                  : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
