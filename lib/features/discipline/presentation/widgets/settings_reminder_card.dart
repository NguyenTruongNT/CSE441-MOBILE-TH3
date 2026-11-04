import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';

import '../../data/fake_discipline_data.dart';

/// Card allowing users to configure daily practice goal and notification reminder with preview mockup.
class SettingsReminderCard extends StatelessWidget {
  const SettingsReminderCard({
    super.key,
    required this.settings,
    required this.reminderService,
    required this.onSaveSettings,
  });

  final LearningSettings settings;
  final ReminderService reminderService;
  final Future<void> Function(LearningSettings newSettings) onSaveSettings;

  static const _goalPresets = [5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final hourStr = settings.reminderHour.toString().padLeft(2, '0');
    final minStr = settings.reminderMinute.toString().padLeft(2, '0');

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cài đặt mục tiêu & Nhắc học',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Goal presets
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mục tiêu học mỗi ngày:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  _getPresetHint(settings.dailyGoalMinutes),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalPresets.map((minutes) {
                final isSelected = settings.dailyGoalMinutes == minutes;
                return ChoiceChip(
                  avatar: Icon(
                    _getPresetIcon(minutes),
                    size: 15,
                    color: isSelected ? primaryColor : Colors.black54,
                  ),
                  label: Text('$minutes phút'),
                  selected: isSelected,
                  selectedColor: primaryColor.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? primaryColor : Colors.black87,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _updateSettings(
                        context,
                        LearningSettings(
                          userId: settings.userId,
                          dailyGoalMinutes: minutes,
                          reminderEnabled: settings.reminderEnabled,
                          reminderHour: settings.reminderHour,
                          reminderMinute: settings.reminderMinute,
                          timeZone: settings.timeZone,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // 2. Reminder Switch & Time Selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhắc học hằng ngày',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.reminderEnabled
                            ? 'Bật nhắc nhở lúc $hourStr:$minStr mỗi ngày'
                            : 'Đang tắt thông báo nhắc nhở',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.reminderEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (enabled) async {
                    if (enabled) {
                      final permission = await reminderService
                          .requestPermission();
                      if (permission != ReminderPermission.granted) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Quyền thông báo bị từ chối. Vui lòng cấp quyền trong Cài đặt.',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    if (context.mounted) {
                      await _updateSettings(
                        context,
                        LearningSettings(
                          userId: settings.userId,
                          dailyGoalMinutes: settings.dailyGoalMinutes,
                          reminderEnabled: enabled,
                          reminderHour: settings.reminderHour,
                          reminderMinute: settings.reminderMinute,
                          timeZone: settings.timeZone,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            if (settings.reminderEnabled) ...[
              const SizedBox(height: 12),
              // Digital Clock Tile
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _pickTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.08),
                        const Color(0xFFF4F3FC),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm_on_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giờ hẹn chuông:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$hourStr:$minStr',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _pickTime(context),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: const Text('Đổi giờ'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Notification Lock-Screen Preview Mockup
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 14,
                          color: Color(0xFF81C784),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Xem trước thông báo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$hourStr:$minStr',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'English AI · Giờ học mỗi ngày',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đã đến lúc luyện phát âm! Hoàn thành ${settings.dailyGoalMinutes} phút hôm nay để giữ vững chuỗi ngày nhé.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Platform Callout Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kIsWeb
                    ? const Color(0xFFFFF8E1)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: kIsWeb
                      ? const Color(0xFFFFE082)
                      : const Color(0xFFA5D6A7),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    kIsWeb ? Icons.info_outline : Icons.check_circle_outline,
                    size: 16,
                    color: kIsWeb
                        ? const Color(0xFFF57F17)
                        : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminderService is FakeReminderService
                          ? 'Chế độ giả lập: không gửi thông báo hệ thống.'
                          : kIsWeb
                          ? 'Ghi chú Web: Thông báo chỉ hỗ trợ khi tab trình duyệt đang mở (không hỗ trợ chạy nền khi đóng trình duyệt).'
                          : 'Android: Nhắc mỗi ngày khoảng $hourStr:$minStr theo múi giờ hồ sơ. Hệ thống tiết kiệm pin có thể làm trễ thông báo; buộc dừng ứng dụng có thể ngăn nhắc học.',
                      style: TextStyle(
                        fontSize: 12,
                        color: kIsWeb
                            ? const Color(0xFFE65100)
                            : const Color(0xFF1B5E20),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPresetIcon(int minutes) {
    switch (minutes) {
      case 5:
        return Icons.bolt_rounded;
      case 10:
        return Icons.timer_rounded;
      case 15:
        return Icons.local_fire_department_rounded;
      case 20:
        return Icons.fitness_center_rounded;
      case 30:
        return Icons.emoji_events_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _getPresetHint(int minutes) {
    switch (minutes) {
      case 5:
        return '⚡ Nhanh gọn';
      case 10:
        return 'Tiêu chuẩn';
      case 15:
        return 'Khuyên dùng';
      case 20:
        return '💪 Chuyên sâu';
      case 30:
        return 'Bứt phá';
      default:
        return '';
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );

    if (picked != null && context.mounted) {
      await _updateSettings(
        context,
        LearningSettings(
          userId: settings.userId,
          dailyGoalMinutes: settings.dailyGoalMinutes,
          reminderEnabled: settings.reminderEnabled,
          reminderHour: picked.hour,
          reminderMinute: picked.minute,
          timeZone: settings.timeZone,
        ),
      );
    }
  }

  Future<void> _updateSettings(
    BuildContext context,
    LearningSettings newSettings,
  ) async {
    try {
      await onSaveSettings(newSettings);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được cài đặt: $error')),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tự động lưu cài đặt học tập.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
