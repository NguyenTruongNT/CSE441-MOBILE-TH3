// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Real-time and post-analysis speech-to-text transcript viewer.
class SpeechTranscriptView extends StatelessWidget {
  const SpeechTranscriptView({
    super.key,
    required this.referenceText,
    required this.liveTranscript,
    required this.isRecording,
    this.finalRecognizedText,
  });

  final String referenceText;
  final String liveTranscript;
  final bool isRecording;
  final String? finalRecognizedText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (isRecording) {
      final displayText = liveTranscript.isNotEmpty
          ? liveTranscript
          : 'Đang lắng nghe giọng nói của bạn… (Hãy đọc to câu mẫu)';

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.record_voice_over_rounded, color: primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bản nháp nhận dạng trực tiếp (nếu thiết bị hỗ trợ):',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: liveTranscript.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: liveTranscript.isEmpty
                          ? Colors.black54
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (finalRecognizedText == null || finalRecognizedText!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Comparison view
    final refWords = referenceText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final userWords = finalRecognizedText!
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_none_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nội dung nhận dạng từ bản ghi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Speech-to-Text',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            '"$finalRecognizedText"',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: primary,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Đối chiếu văn bản theo vị trí từ (không dùng để tính điểm âm vị):',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(refWords.length, (i) {
              final refWord = refWords[i].replaceAll(RegExp(r'[^\w]'), '');
              final userWord = i < userWords.length
                  ? userWords[i].replaceAll(RegExp(r'[^\w]'), '')
                  : null;

              final isMatch =
                  userWord != null &&
                  userWord.toLowerCase() == refWord.toLowerCase();

              final badgeColor = isMatch
                  ? const Color(0xFF1B873F)
                  : (userWord != null ? const Color(0xFFD97706) : Colors.grey);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      refWord,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                    if (userWord != null && !isMatch) ...[
                      const SizedBox(height: 2),
                      Text(
                        '[$userWord]',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
