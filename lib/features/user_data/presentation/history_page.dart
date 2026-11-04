import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/shared/app_states.dart';
import '../../../core/contracts/contracts.dart';
import '../../../core/learning_time.dart';
import 'practice_result_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.userRepository,
    required this.learningRepository,
    this.clock,
  });

  final UserRepository userRepository;
  final LearningRepository learningRepository;

  /// Cho phép truyền thời gian cố định khi kiểm thử.
  final DateTime Function()? clock;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  String? _errorMessage;

  UserProfile? _selectedProfile;
  List<_HistoryEntry> _entries = const <_HistoryEntry>[];
  DateTimeRange? _selectedDateRange;
  int _loadRevision = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
    for (final repository in [
      widget.userRepository,
      widget.learningRepository,
    ]) {
      if (repository is Listenable) {
        (repository).addListener(_onDataChanged);
      }
    }
  }

  void _onDataChanged() => unawaited(_loadHistory(showLoading: false));

  @override
  void dispose() {
    for (final repository in [
      widget.userRepository,
      widget.learningRepository,
    ]) {
      if (repository is Listenable) {
        (repository).removeListener(_onDataChanged);
      }
    }
    super.dispose();
  }

  DateTime get _nowUtc {
    return (widget.clock ?? DateTime.now)().toUtc();
  }

  Future<void> _loadHistory({bool showLoading = true}) async {
    if (!mounted) {
      return;
    }
    final revision = ++_loadRevision;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final UserProfile? selectedProfile = await widget.userRepository
          .getSelectedProfile();

      if (selectedProfile == null) {
        if (!mounted || revision != _loadRevision) {
          return;
        }

        setState(() {
          _selectedProfile = null;
          _entries = const <_HistoryEntry>[];
          _isLoading = false;
          _errorMessage = null;
        });

        return;
      }

      final DateTime fromUtc;
      final DateTime toUtc;

      if (_selectedDateRange == null) {
        fromUtc = DateTime.utc(1);
        toUtc = _nowUtc.add(const Duration(days: 1));
      } else {
        final range = profileDateRangeUtc(
          _selectedDateRange!.start,
          _selectedDateRange!.end,
          selectedProfile.timeZone,
        );
        fromUtc = range.fromUtc;
        toUtc = range.toUtc;
      }

      final List<PracticeSession> sessions = await widget.learningRepository
          .listSessions(
            userId: selectedProfile.id,
            fromUtc: fromUtc,
            toUtc: toUtc,
          );

      final List<_HistoryEntry> entries = <_HistoryEntry>[];

      for (final PracticeSession session in sessions) {
        final PronunciationResult? result = await widget.learningRepository
            .getResult(userId: selectedProfile.id, sessionId: session.id);

        entries.add(_HistoryEntry(session: session, result: result));
      }

      if (!mounted || revision != _loadRevision) {
        return;
      }

      setState(() {
        _selectedProfile = selectedProfile;
        _entries = List<_HistoryEntry>.unmodifiable(entries);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted || revision != _loadRevision) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải lịch sử luyện tập: $error';
      });
    }
  }

  Future<void> _chooseDateRange() async {
    final DateTime now = profileTime(
      _nowUtc,
      _selectedProfile?.timeZone ?? 'Asia/Ho_Chi_Minh',
    );

    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      helpText: 'Chọn khoảng ngày',
      cancelText: 'Hủy',
      confirmText: 'Áp dụng',
      saveText: 'Áp dụng',
      fieldStartHintText: 'Ngày bắt đầu',
      fieldEndHintText: 'Ngày kết thúc',
    );

    if (range == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDateRange = range;
    });

    await _loadHistory(showLoading: false);
  }

  Future<void> _clearDateRange() async {
    if (_selectedDateRange == null) {
      return;
    }

    setState(() {
      _selectedDateRange = null;
    });

    await _loadHistory(showLoading: false);
  }

  Future<void> _openDetails(_HistoryEntry entry) async {
    final PronunciationResult? result = entry.result;

    if (result == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Phiên này không có kết quả phát âm.')),
        );

      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PracticeResultDetailPage(
            session: entry.session,
            result: result,
            timeZone: _selectedProfile!.timeZone,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingState(message: 'Đang tải lịch sử luyện tập…');
    }

    if (_errorMessage != null) {
      return AppMessageState(
        title: 'Lỗi tải lịch sử',
        message: _errorMessage!,
        icon: Icons.error_outline_rounded,
        onRetry: _loadHistory,
      );
    }

    if (_selectedProfile == null) {
      return const AppMessageState(
        title: 'Chưa chọn tài khoản',
        message: 'Hãy chọn tài khoản tại màn hình đăng nhập để xem lịch sử luyện tập.',
        icon: Icons.person_off_outlined,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 800;

        return RefreshIndicator(
          onRefresh: () {
            return _loadHistory(showLoading: false);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, isWide: isWide),
                    const SizedBox(height: 20),
                    _buildSummary(context),
                    const SizedBox(height: 20),
                    if (_entries.isEmpty)
                      _buildEmptyState(context)
                    else
                      _buildHistoryList(context, isWide: isWide),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isWide}) {
    final ThemeData theme = Theme.of(context);

    final Widget information = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử luyện tập',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hồ sơ: ${_selectedProfile!.displayName}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          _selectedDateRange == null
              ? 'Đang hiển thị toàn bộ lịch sử.'
              : 'Từ ${formatCalendarDate(_selectedDateRange!.start)} '
                    'đến ${formatCalendarDate(_selectedDateRange!.end)}.',
        ),
      ],
    );

    final Widget filterButton = OutlinedButton.icon(
      key: const ValueKey('history-date-filter-button'),
      onPressed: _chooseDateRange,
      icon: const Icon(Icons.date_range_outlined),
      label: const Text('Lọc theo ngày'),
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isWide
            ? Row(
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 20),
                  filterButton,
                  if (_selectedDateRange != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      key: const ValueKey('clear-history-filter-button'),
                      onPressed: _clearDateRange,
                      tooltip: 'Xóa bộ lọc',
                      icon: const Icon(Icons.filter_alt_off_outlined),
                    ),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  information,
                  const SizedBox(height: 20),
                  filterButton,
                  if (_selectedDateRange != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      key: const ValueKey('clear-history-filter-button'),
                      onPressed: _clearDateRange,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Xóa bộ lọc'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final int totalSeconds = _entries.fold<int>(0, (
      int previous,
      _HistoryEntry entry,
    ) {
      return previous + entry.session.durationSeconds;
    });

    final List<double> scores = _entries
        .where((_HistoryEntry entry) => entry.result != null)
        .map((_HistoryEntry entry) => entry.result!.overallScore)
        .toList();

    final double? averageScore = scores.isEmpty
        ? null
        : scores.reduce((double first, double second) {
                return first + second;
              }) /
              scores.length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          icon: Icons.history_rounded,
          label: 'Số phiên',
          value: '${_entries.length}',
          color: theme.colorScheme.primary,
        ),
        _SummaryCard(
          icon: Icons.timer_outlined,
          label: 'Thời gian luyện',
          value: _formatDuration(totalSeconds),
          color: theme.colorScheme.tertiary,
        ),
        _SummaryCard(
          icon: Icons.analytics_outlined,
          label: 'Điểm trung bình',
          value: averageScore == null
              ? 'Chưa có'
              : averageScore.toStringAsFixed(1),
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có phiên luyện tập',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDateRange == null
                  ? 'Các phiên luyện tập đã lưu sẽ xuất hiện tại đây.'
                  : 'Không có phiên luyện tập trong khoảng ngày đã chọn.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, {required bool isWide}) {
    if (isWide) {
      return LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final entry in _entries)
              SizedBox(
                width: (constraints.maxWidth - 16) / 2,
                child: _HistoryCard(
                  entry: entry,
                  timeZone: _selectedProfile!.timeZone,
                  onOpen: () => unawaited(_openDetails(entry)),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entries.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        final _HistoryEntry entry = _entries[index];

        return _HistoryCard(
          entry: entry,
          timeZone: _selectedProfile!.timeZone,
          onOpen: () {
            unawaited(_openDetails(entry));
          },
        );
      },
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.session, required this.result});

  final PracticeSession session;
  final PronunciationResult? result;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.onOpen,
    required this.timeZone,
  });

  final _HistoryEntry entry;
  final VoidCallback onOpen;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final (IconData statusIcon, String statusLabel, Color statusColor) =
        _practiceStatusAppearance(context, entry.session.status);

    return Card(
      key: ValueKey('history-session-${entry.session.id}'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.result?.referenceText ?? entry.session.exerciseId,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (entry.result != null) ...[
              const SizedBox(height: 6),
              Text(entry.session.exerciseId, style: theme.textTheme.labelSmall),
            ],
            const SizedBox(height: 14),
            Text(formatProfileDateTime(entry.session.startedAt, timeZone)),
            const SizedBox(height: 6),
            Text(
              'Thời lượng: '
              '${_formatDuration(entry.session.durationSeconds)}',
            ),
            const SizedBox(height: 6),
            Text(
              entry.result == null
                  ? 'Điểm: Không có kết quả'
                  : 'Điểm: '
                        '${entry.result!.overallScore.toStringAsFixed(1)}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('open-result-${entry.session.id}'),
                onPressed: entry.result == null ? null : onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  entry.result == null ? 'Không có chi tiết' : 'Xem chi tiết',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 230,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

(IconData, String, Color) _practiceStatusAppearance(
  BuildContext context,
  PracticeStatus status,
) {
  final ColorScheme scheme = Theme.of(context).colorScheme;

  switch (status) {
    case PracticeStatus.completed:
      return (
        Icons.check_circle_outline_rounded,
        'Hoàn thành',
        Colors.green.shade700,
      );

    case PracticeStatus.cancelled:
      return (Icons.cancel_outlined, 'Đã hủy', scheme.outline);

    case PracticeStatus.analysisFailed:
      return (Icons.error_outline_rounded, 'Phân tích lỗi', scheme.error);
  }
}

String _formatDuration(int totalSeconds) {
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;

  if (minutes == 0) {
    return '$seconds giây';
  }

  if (seconds == 0) {
    return '$minutes phút';
  }

  return '$minutes phút $seconds giây';
}
