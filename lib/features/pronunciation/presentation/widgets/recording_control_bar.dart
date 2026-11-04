// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Control bar with microphone trigger, active recording timer,
/// audio cancellation, and state feedback.
class RecordingControlBar extends StatelessWidget {
  const RecordingControlBar({
    super.key,
    required this.isRecording,
    required this.elapsedMilliseconds,
    required this.hasPermission,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onRequestPermission,
  });

  final bool isRecording;
  final int elapsedMilliseconds;
  final bool hasPermission;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (!hasPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.mic_off_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ứng dụng cần quyền micro để ghi âm giọng nói của bạn.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onRequestPermission,
              child: const Text('Cấp quyền'),
            ),
          ],
        ),
      );
    }

    final seconds = elapsedMilliseconds ~/ 1000;
    final timerText =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isRecording
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecording ? primary : theme.colorScheme.outlineVariant,
          width: isRecording ? 1.5 : 1,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          if (isRecording) ...[
            // Cancel button
            IconButton.filledTonal(
              onPressed: onCancelRecording,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Hủy ghi âm',
            ),
            const SizedBox(width: 8),
            // Timer & recording indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingRedDot(),
                const SizedBox(width: 8),
                Text(
                  timerText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Finish recording button
            FilledButton.icon(
              onPressed: onStopRecording,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Dừng & Phân tích'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ] else ...[
            // Ready to record
            FilledButton.icon(
              onPressed: onStartRecording,
              icon: const Icon(Icons.mic_rounded, size: 24),
              label: const Text('Bắt đầu ghi âm'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFFDC2626),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
