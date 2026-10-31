import 'package:flutter/material.dart';

/// Inject pages using closures that pass real services into feature constructors.
/// Null builders intentionally display integration placeholders.
class AppPages {
  const AppPages({
    this.progress,
    this.pronunciation,
    this.history,
    this.profile,
  });

  final WidgetBuilder? progress;
  final WidgetBuilder? pronunciation;
  final WidgetBuilder? history;
  final WidgetBuilder? profile;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages});

  final AppPages pages;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _sections = [
    _Section(
      title: 'Tiến độ',
      icon: Icons.insights_outlined,
      owner: 'Lý Đình Sơn',
      headline: 'Mỗi ngày một bước tiến.',
      description:
          'Duy trì thói quen luyện tiếng Anh và theo dõi hành trình của bạn.',
      items: [
        'Mục tiêu mỗi ngày',
        'Chuỗi ngày luyện tập',
        'Thống kê thời gian học',
      ],
    ),
    _Section(
      title: 'Luyện phát âm',
      icon: Icons.mic_none_rounded,
      owner: 'Vũ Hải Đăng',
      headline: 'Tự tin hơn qua từng âm.',
      description:
          'Nghe mẫu, luyện nói và nhận phản hồi phát âm theo từng âm vị.',
      items: [
        'Bài học và phiên âm IPA',
        'Ghi âm và phân tích AI',
        'Điểm số và bài tập cải thiện',
      ],
    ),
    _Section(
      title: 'Lịch sử',
      icon: Icons.history_rounded,
      owner: 'Vũ Tuấn Khanh',
      headline: 'Nhìn lại để tiến xa hơn.',
      description:
          'Xem lại các phiên luyện tập và những âm cần tiếp tục cải thiện.',
      items: [
        'Danh sách phiên luyện',
        'Kết quả phát âm đã lưu',
        'Lọc theo hồ sơ và ngày học',
      ],
    ),
    _Section(
      title: 'Hồ sơ',
      icon: Icons.person_outline_rounded,
      owner: 'Vũ Tuấn Khanh',
      headline: 'Hành trình của riêng bạn.',
      description: 'Quản lý hồ sơ và giữ dữ liệu học tập riêng cho từng người.',
      items: [
        'Tạo và chọn hồ sơ',
        'Thông tin người học',
        'Dữ liệu lưu qua các lần mở lại',
      ],
    ),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final builders = [
      widget.pages.progress,
      widget.pages.pronunciation,
      widget.pages.history,
      widget.pages.profile,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        return Scaffold(
          appBar: AppBar(
            title: Text(_sections[_selectedIndex].title),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Tooltip(
                  message: 'CSE441 · Lớp 65KTPM · Nhóm 12',
                  child: Icon(Icons.school_outlined),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) ...[
                  NavigationRail(
                    extended: constraints.maxWidth >= 1100,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _select,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Icon(Icons.record_voice_over_rounded, size: 32),
                    ),
                    labelType: constraints.maxWidth >= 1100
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    destinations: [
                      for (final section in _sections)
                        NavigationRailDestination(
                          icon: Icon(section.icon),
                          label: Text(section.title),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      for (var index = 0; index < _sections.length; index++)
                        KeyedSubtree(
                          key: ValueKey('page-$index'),
                          child: builders[index] == null
                              ? _IntegrationPage(section: _sections[index])
                              : Builder(builder: builders[index]!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final section in _sections)
                      NavigationDestination(
                        icon: Icon(section.icon),
                        label: section.title,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _Section {
  const _Section({
    required this.title,
    required this.icon,
    required this.owner,
    required this.headline,
    required this.description,
    required this.items,
  });

  final String title;
  final IconData icon;
  final String owner;
  final String headline;
  final String description;
  final List<String> items;
}

class _IntegrationPage extends StatelessWidget {
  const _IntegrationPage({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ENGLISH AI / NHÓM 12',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(section.icon, size: 36),
                      const SizedBox(height: 20),
                      Text(
                        section.headline,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        section.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Nội dung dự kiến', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final item in section.items)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_outward,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Chờ tích hợp module · Phụ trách: ${section.owner}. '
                    'Đây là màn hình khung, chưa có dữ liệu hoặc chức năng thực tế.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
