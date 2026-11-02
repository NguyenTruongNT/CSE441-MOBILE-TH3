import 'package:flutter/material.dart';
import '../../../app/shared/app_states.dart';
import '../../../core/contracts/contracts.dart';
import '../data/fake_discipline_data.dart';
import '../models/discipline_stats.dart';
import '../services/discipline_calculator.dart';
import '../services/local_reminder_service.dart';
import 'widgets/daily_goal_ring.dart';
import 'widgets/demo_simulation_bar.dart';
import 'widgets/progress_header_card.dart';
import 'widgets/settings_reminder_card.dart';
import 'widgets/streak_hero_card.dart';
import 'widgets/weekly_bar_chart.dart';

/// Complete responsive Progress and Discipline dashboard screen.
class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    this.userRepository,
    this.learningRepository,
    this.reminderService,
  });

  final UserRepository? userRepository;
  final LearningRepository? learningRepository;
  final ReminderService? reminderService;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late final LearningRepository _learningRepository;
  late final ReminderService _reminderService;
  final DisciplineCalculator _calculator = const DisciplineCalculator();

  bool _isLoading = true;
  String? _errorMessage;

  String _currentUserId = 'default-user-01';
  String _displayName = 'Học viên';
  late LearningSettings _settings;
  late DisciplineStats _stats;

  NotificationPayload? _activeNotificationBanner;

  @override
  void initState() {
    super.initState();
    _learningRepository =
        widget.learningRepository ?? FakeLearningRepository();
    _reminderService = widget.reminderService ?? LocalReminderService();

    final service = _reminderService;
    if (service is LocalReminderService) {
      service.onNotificationTriggered.addListener(_handleNotificationReceived);
    }

    _loadDashboardData();
  }

  @override
  void dispose() {
    final service = _reminderService;
    if (service is LocalReminderService) {
      service.onNotificationTriggered.removeListener(_handleNotificationReceived);
    }
    super.dispose();
  }

  void _handleNotificationReceived() {
    if (!mounted) return;
    final service = _reminderService;
    if (service is LocalReminderService) {
      final payload = service.onNotificationTriggered.value;
      if (payload != null) {
        setState(() {
          _activeNotificationBanner = payload;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Resolve current active user
      if (widget.userRepository != null) {
        final profile = await widget.userRepository!.getSelectedProfile();
        if (profile != null) {
          _currentUserId = profile.id;
          _displayName = profile.displayName;
        }
      }

      // 2. Load settings for user
      _settings = await _learningRepository.getSettings(_currentUserId);

      // 3. Load sessions for the past 30 days
      final nowUtc = DateTime.now().toUtc();
      final fromUtc = nowUtc.subtract(const Duration(days: 30));
      final toUtc = nowUtc.add(const Duration(days: 1));

      final sessions = await _learningRepository.listSessions(
        userId: _currentUserId,
        fromUtc: fromUtc,
        toUtc: toUtc,
      );

      // 4. Calculate stats
      _stats = _calculator.computeStats(
        sessions: sessions,
        settings: _settings,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu tiến độ: $e';
      });
    }
  }

  Future<void> _handleSaveSettings(LearningSettings newSettings) async {
    await _learningRepository.saveSettings(newSettings);
    await _reminderService.scheduleDaily(newSettings);
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingState(message: 'Đang tải dữ liệu tiến độ…');
    }

    if (_errorMessage != null) {
      return AppMessageState(
        title: 'Lỗi tải dữ liệu',
        message: _errorMessage!,
        icon: Icons.error_outline_rounded,
        onRetry: _loadDashboardData,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    if (_activeNotificationBanner != null) ...[
                      _buildHeadsUpNotificationBanner(
                        _activeNotificationBanner!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    isWide ? _buildDesktopLayout() : _buildMobileLayout(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Heads-Up Floating Notification Banner visible on both Web and Mobile
  Widget _buildHeadsUpNotificationBanner(NotificationPayload payload) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFFB74D),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  payload.body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
            onPressed: () {
              setState(() {
                _activeNotificationBanner = null;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 2-Column responsive layout for Desktop & Web widescreen
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        ProgressHeaderCard(
          displayName: _displayName,
          stats: _stats,
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Column: Analytics & Charts
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  StreakHeroCard(stats: _stats),
                  const SizedBox(height: 16),
                  DailyGoalRing(stats: _stats),
                  const SizedBox(height: 16),
                  WeeklyBarChart(stats: _stats),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Side Column: Settings & Demo Actions
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SettingsReminderCard(
                    settings: _settings,
                    reminderService: _reminderService,
                    onSaveSettings: _handleSaveSettings,
                  ),
                  const SizedBox(height: 16),
                  DemoSimulationBar(
                    userId: _currentUserId,
                    repository: _learningRepository,
                    reminderService: _reminderService,
                    onDataChanged: _loadDashboardData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single column scrollable layout for Mobile viewports (< 800px)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        ProgressHeaderCard(
          displayName: _displayName,
          stats: _stats,
        ),
        const SizedBox(height: 16),
        StreakHeroCard(stats: _stats),
        const SizedBox(height: 16),
        DailyGoalRing(stats: _stats),
        const SizedBox(height: 16),
        WeeklyBarChart(stats: _stats),
        const SizedBox(height: 16),
        SettingsReminderCard(
          settings: _settings,
          reminderService: _reminderService,
          onSaveSettings: _handleSaveSettings,
        ),
        const SizedBox(height: 16),
        DemoSimulationBar(
          userId: _currentUserId,
          repository: _learningRepository,
          reminderService: _reminderService,
          onDataChanged: _loadDashboardData,
        ),
      ],
    );
  }
}
