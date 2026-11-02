import 'dart:async';

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
    this.clock,
  });

  final UserRepository? userRepository;
  final LearningRepository? learningRepository;
  final ReminderService? reminderService;
  final Clock? clock;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with WidgetsBindingObserver {
  late final LearningRepository _learningRepository;
  late final ReminderService _reminderService;
  late final DisciplineCalculator _calculator;
  Timer? _refreshTimer;
  bool _refreshing = false;
  bool _saving = false;
  bool _reloadRequested = false;
  String? _scheduledUser;
  String? _scheduleKey;
  List<UserProfile> _profiles = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _reminderError;

  String _currentUserId = 'default-user-01';
  String _displayName = 'Học viên';
  late LearningSettings _settings;
  late DisciplineStats _stats;

  NotificationPayload? _activeNotificationBanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calculator = DisciplineCalculator(clock: widget.clock);
    _learningRepository = widget.learningRepository ?? FakeLearningRepository();
    _reminderService = widget.reminderService ?? LocalReminderService();
    final users = widget.userRepository;
    if (users is Listenable) (users as Listenable).addListener(_onDataChanged);
    final learning = _learningRepository;
    if (learning is Listenable) {
      (learning as Listenable).addListener(_onDataChanged);
    }
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _onDataChanged(),
    );

    final service = _reminderService;
    if (service is LocalReminderService) {
      service.onNotificationTriggered.addListener(_handleNotificationReceived);
    }

    _loadDashboardData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final users = widget.userRepository;
    if (users is Listenable) {
      (users as Listenable).removeListener(_onDataChanged);
    }
    final learning = _learningRepository;
    if (learning is Listenable) {
      (learning as Listenable).removeListener(_onDataChanged);
    }
    final service = _reminderService;
    if (service is LocalReminderService) {
      service.onNotificationTriggered.removeListener(
        _handleNotificationReceived,
      );
      if (widget.reminderService == null) service.dispose();
    }
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) unawaited(_loadDashboardData());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleKey = null;
      _onDataChanged();
    }
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
    if (!mounted) return;
    if (_refreshing || _saving) {
      _reloadRequested = true;
      return;
    }
    _refreshing = true;

    try {
      // 1. Resolve current active user
      UserProfile? profile;
      if (widget.userRepository != null) {
        profile = await widget.userRepository!.getSelectedProfile();
        if (profile == null) {
          if (_scheduledUser != null) {
            await _reminderService.cancel(_scheduledUser!);
          }
          _scheduledUser = null;
          _scheduleKey = null;
          throw StateError('Hãy chọn hồ sơ học tập trước.');
        }
        _profiles = await widget.userRepository!.listProfiles();
        _currentUserId = profile.id;
        _displayName = profile.displayName;
      }
      if (!mounted) return;
      if (_scheduledUser != null && _scheduledUser != _currentUserId) {
        await _reminderService.cancel(_scheduledUser!);
        _scheduleKey = null;
        _scheduledUser = null;
      }

      // 2. Load settings for user
      _settings = await _learningRepository.getSettings(_currentUserId);
      if (profile != null && _settings.timeZone != profile.timeZone) {
        _settings = LearningSettings(
          userId: _currentUserId,
          dailyGoalMinutes: _settings.dailyGoalMinutes,
          reminderEnabled: _settings.reminderEnabled,
          reminderHour: _settings.reminderHour,
          reminderMinute: _settings.reminderMinute,
          timeZone: profile.timeZone,
        );
      }

      // All history is needed for streaks longer than the chart's 7-day window.
      final nowUtc = (widget.clock ?? DateTime.now)().toUtc();
      final fromUtc = DateTime.utc(1);
      final toUtc = nowUtc.add(const Duration(microseconds: 1));

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
      if (!mounted) return;
      final key =
          '${_settings.userId}/${_settings.reminderEnabled}/${_settings.reminderHour}/${_settings.reminderMinute}/${_settings.timeZone}/${_settings.dailyGoalMinutes}';
      if (key != _scheduleKey) {
        try {
          await _reminderService.scheduleDaily(_settings);
          _scheduledUser = _currentUserId;
          _scheduleKey = key;
          _reminderError = null;
        } catch (error) {
          _reminderError = 'Chưa đặt được nhắc học: $error';
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu tiến độ: $e';
      });
    } finally {
      _refreshing = false;
      if (_reloadRequested && mounted) {
        _reloadRequested = false;
        unawaited(_loadDashboardData());
      }
    }
  }

  Future<void> _handleSaveSettings(LearningSettings newSettings) async {
    if (_saving || _refreshing) {
      throw StateError('Đang xử lý cài đặt, vui lòng thử lại.');
    }
    _saving = true;
    try {
      await _reminderService.scheduleDaily(newSettings);
      try {
        await _learningRepository.saveSettings(newSettings);
      } catch (_) {
        await _reminderService.scheduleDaily(_settings);
        rethrow;
      }
      _scheduleKey = null;
    } finally {
      _saving = false;
      if (_reloadRequested && mounted) {
        _reloadRequested = false;
        unawaited(_loadDashboardData());
      }
    }
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
                    if (_reminderError != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_reminderError!),
                        ),
                      ),
                    if (_profiles.isNotEmpty &&
                        _learningRepository is FakeLearningRepository)
                      DropdownButton<String>(
                        value: _currentUserId,
                        isExpanded: true,
                        items: [
                          for (final profile in _profiles)
                            DropdownMenuItem(
                              value: profile.id,
                              child: Text(
                                'Hồ sơ demo: ${profile.displayName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (id) async {
                          if (id != null) {
                            await widget.userRepository!.selectProfile(id);
                            await _loadDashboardData();
                          }
                        },
                      ),
                    if (_learningRepository is FakeLearningRepository) ...[
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Dữ liệu giả lập · Dùng để phát triển và demo. '
                            'Tiến độ và cài đặt sẽ đặt lại khi khởi động lại ứng dụng.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white60,
              size: 20,
            ),
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
        ProgressHeaderCard(displayName: _displayName, stats: _stats),
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
                  if (_learningRepository is FakeLearningRepository)
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
        ProgressHeaderCard(displayName: _displayName, stats: _stats),
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
        if (_learningRepository is FakeLearningRepository)
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
