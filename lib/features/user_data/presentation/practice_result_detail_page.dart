import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/learning_time.dart';

class PracticeResultDetailPage extends StatelessWidget {
  const PracticeResultDetailPage({
    super.key,
    required this.session,
    required this.result,
    this.timeZone = 'Asia/Ho_Chi_Minh',
  });

  final PracticeSession session;
  final PronunciationResult result;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết kết quả')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 32 : 16,
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScoreHeader(context),
                const SizedBox(height: 16),
                _buildSessionInformation(context),
                const SizedBox(height: 16),
                _buildTranscriptSection(context),
                const SizedBox(height: 16),
                Text(
                  'Phản hồi phát âm',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (result.phonemes.isEmpty)
                  const Card(
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không có dữ liệu âm vị để hiển thị.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final PhonemeFeedback feedback in result.phonemes) ...[
                    _PhonemeFeedbackCard(feedback: feedback),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int roundedScore = result.overallScore.round();

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$roundedScore',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Điểm phát âm',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _scoreDescription(result.overallScore),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.provider} · '
                    '${result.modelVersion}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInformation(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _InformationItem(
              icon: Icons.timer_outlined,
              label: 'Thời lượng',
              value: '${session.durationSeconds} giây',
            ),
            _InformationItem(
              icon: Icons.calendar_today_outlined,
              label: 'Thời gian luyện',
              value: formatProfileDateTime(session.startedAt, timeZone),
            ),
            _InformationItem(
              icon: Icons.analytics_outlined,
              label: 'Thời gian phân tích',
              value: formatProfileDateTime(result.analyzedAt, timeZone),
            ),
            _InformationItem(
              icon: Icons.fingerprint_rounded,
              label: 'Mã phiên',
              value: session.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nội dung phát âm',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Văn bản chuẩn',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SelectableText(result.referenceText),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Văn bản nhận dạng',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SelectableText(result.recognizedText),
          ],
        ),
      ),
    );
  }
}

class _PhonemeFeedbackCard extends StatelessWidget {
  const _PhonemeFeedbackCard({required this.feedback});

  final PhonemeFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final (IconData icon, String statusLabel, Color color) = _statusAppearance(
      context,
      feedback.status,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feedback.word,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  feedback.isInsertion &&
                          feedback.status == PhonemeStatus.needsPractice
                      ? 'Âm thừa'
                      : statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _SmallInformation(
                  label: 'IPA chuẩn',
                  value: feedback.isInsertion
                      ? 'Không có âm tương ứng trong mẫu'
                      : feedback.expectedIpa,
                ),
                _SmallInformation(
                  label: 'IPA nhận dạng',
                  value: feedback.recognizedIpa ?? 'Không có',
                ),
                _SmallInformation(
                  label: 'Điểm',
                  value: feedback.score == null
                      ? 'Chưa đánh giá'
                      : feedback.score!.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(feedback.suggestion, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInformation extends StatelessWidget {
  const _SmallInformation({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}

(IconData, String, Color) _statusAppearance(
  BuildContext context,
  PhonemeStatus status,
) {
  final ColorScheme scheme = Theme.of(context).colorScheme;

  switch (status) {
    case PhonemeStatus.correct:
      return (
        Icons.check_circle_outline_rounded,
        'Đúng',
        Colors.green.shade700,
      );

    case PhonemeStatus.needsPractice:
      return (Icons.info_outline_rounded, 'Cần luyện thêm', scheme.error);

    case PhonemeStatus.notAssessed:
      return (Icons.help_outline_rounded, 'Chưa đánh giá', scheme.outline);
  }
}

String _scoreDescription(double score) {
  if (score >= 90) {
    return 'Phát âm rất tốt và ổn định.';
  }

  if (score >= 75) {
    return 'Phát âm khá tốt, vẫn còn một số điểm cần luyện.';
  }

  if (score >= 50) {
    return 'Cần luyện thêm các âm được đánh dấu.';
  }

  return 'Nên nghe lại âm mẫu và luyện từng từ chậm hơn.';
}
