import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';

/// Card allowing users to configure daily practice goal and notification reminder.
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
            Text(
              'Mục tiêu học mỗi ngày (phút):',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalPresets.map((minutes) {
                final isSelected = settings.dailyGoalMinutes == minutes;
                return ChoiceChip(
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

            // 2. Reminder settings
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
                      // Request permission first
                      final permission =
                          await reminderService.requestPermission();
                      if (permission == ReminderPermission.denied &&
                          context.mounted) {
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
                      _updateSettings(
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
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pickTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4DFDC)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giờ nhắc:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$hourStr:$minStr',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Platform limitations banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kIsWeb ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      kIsWeb ? const Color(0xFFFFE082) : const Color(0xFFA5D6A7),
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
                      kIsWeb
                          ? 'Ghi chú Web: Thông báo đẩy chỉ hỗ trợ khi trình duyệt đang mở (không hỗ trợ chạy nền khi đóng trình duyệt).'
                          : 'Android: Đã tích hợp chuông nhắc hằng ngày vào đúng $hourStr:$minStr theo giờ hệ thống.',
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
    await onSaveSettings(newSettings);
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
