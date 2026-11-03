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
        side: const BorderSide(color: Color(0xFFDDD9F3)),
      ),
      color: const Color(0xFFF1F0FC),
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
                  color: Color(0xFF6554D9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Công cụ nghiệm thu & Mô phỏng (Demo Tool)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6554D9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Mô phỏng nhanh các tình huống thực tế để kiểm tra chuỗi streak, tiến độ và thông báo:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Button 1: Add 5 minutes (Matches test finder)
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
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                  ),
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
      return;
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
            body: 'Đã đến giờ luyện tiếng Anh hôm nay! Hãy giữ vững ngọn lửa chuỗi ngày nhé 🔥',
          );
    } else if (reminderService is FakeReminderService) {
      sent = await (reminderService as FakeReminderService)
          .sendImmediateTestNotification(
            title: 'English AI · Nhắc học',
            body: 'Đã đến giờ luyện tiếng Anh hôm nay! Hãy giữ vững ngọn lửa chuỗi ngày nhé 🔥',
          );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? reminderService is FakeReminderService
                      ? 'Đã mô phỏng thông báo; chưa gửi thông báo hệ thống.'
                      : 'Đã kích hoạt thông báo thử nghiệm thành công!'
                : 'Không thể kích hoạt thông báo trên nền tảng này.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
