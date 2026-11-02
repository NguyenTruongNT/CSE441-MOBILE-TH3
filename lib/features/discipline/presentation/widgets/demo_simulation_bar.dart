import 'package:flutter/material.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import '../../data/fake_discipline_data.dart';
import '../../services/local_reminder_service.dart';

/// Interactive tool for teachers and evaluators to quickly simulate practice sessions and test notifications.
class DemoSimulationBar extends StatelessWidget {
  const DemoSimulationBar({
    super.key,
    required this.userId,
    required this.repository,
    required this.reminderService,
    required this.onDataChanged,
  });

  final String userId;
  final LearningRepository repository;
  final ReminderService reminderService;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFCFDCD8)),
      ),
      color: const Color(0xFFF0F7F5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  size: 20,
                  color: Color(0xFF12796F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Công cụ nghiệm thu & Mô phỏng',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12796F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Thao tác nhanh để kiểm tra tính năng streak, vòng tiến độ và thông báo mà không cần chờ đợi:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Button 1: Add 5 minutes
                FilledButton.tonalIcon(
                  onPressed: () => _addMinutes(context, 5),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+5p học hôm nay'),
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),

                // Button 2: Add 15 minutes (Reach goal)
                FilledButton.tonalIcon(
                  onPressed: () => _addMinutes(context, 15),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('+15p (Đạt mục tiêu)'),
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),

                // Button 3: Trigger Test Notification
                OutlinedButton.icon(
                  onPressed: () => _testNotification(context),
                  icon: const Icon(Icons.notifications_active_outlined, size: 16),
                  label: const Text('Bắn thông báo thử'),
                  style: OutlinedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMinutes(BuildContext context, int minutes) async {
    if (repository is FakeLearningRepository) {
      await (repository as FakeLearningRepository).addQuickSession(
        userId: userId,
        minutes: minutes,
      );
    } else {
      final now = DateTime.now().toUtc();
      final session = PracticeSession(
        id: 'sim-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        exerciseId: 'demo-quick-practice',
        startedAt: now.subtract(Duration(minutes: minutes)),
        endedAt: now,
        durationSeconds: minutes * 60,
        status: PracticeStatus.completed,
      );
      await repository.savePractice(session: session);
    }

    onDataChanged();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $minutes phút luyện tập cho hôm nay!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testNotification(BuildContext context) async {
    bool sent = false;
    if (reminderService is LocalReminderService) {
      sent = await (reminderService as LocalReminderService)
          .sendImmediateTestNotification(
            title: 'English AI · Nhắc học',
            body:
                'Đã đến giờ luyện tiếng Anh hôm nay! Hãy giữ vững ngọn lửa chuỗi ngày nhé 🔥',
          );
    } else if (reminderService is FakeReminderService) {
      sent = await (reminderService as FakeReminderService)
          .sendImmediateTestNotification(
            title: 'English AI · Nhắc học',
            body:
                'Đã đến giờ luyện tiếng Anh hôm nay! Hãy giữ vững ngọn lửa chuỗi ngày nhé 🔥',
          );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Đã kích hoạt thông báo thử nghiệm thành công!'
                : 'Không thể kích hoạt thông báo trên nền tảng này.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
