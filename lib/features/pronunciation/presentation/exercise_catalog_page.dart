import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../domain/exercise_models.dart';
import 'widgets/exercise_card.dart';

/// Browsing never initializes the microphone, TTS or an assessment request.
class ExerciseCatalogPage extends StatefulWidget {
  const ExerciseCatalogPage({
    super.key,
    required this.exercises,
    required this.onSelect,
  });

  final List<ExerciseDetail> exercises;
  final ValueChanged<ExerciseDetail> onSelect;

  @override
  State<ExerciseCatalogPage> createState() => _ExerciseCatalogPageState();
}

class _ExerciseCatalogPageState extends State<ExerciseCatalogPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _category = 'Tất cả';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _resetFilters() => setState(() {
    _search.clear();
    _category = 'Tất cả';
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyword = _search.text.trim().toLowerCase();
    final categories = [
      'Tất cả',
      ...{for (final e in widget.exercises) e.category},
    ];
    final filtered = widget.exercises.where((exercise) {
      if (_category != 'Tất cả' && exercise.category != _category) return false;
      return keyword.isEmpty ||
          '${exercise.referenceText} ${exercise.referenceIpa} '
                  '${exercise.category} ${exercise.description} '
                  '${exercise.targetPhonemes.join(' ')}'
              .toLowerCase()
              .contains(keyword);
    }).toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return SingleChildScrollView(
            key: const PageStorageKey('exercise-catalog-scroll'),
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              wide ? 28 : 16,
              20,
              wide ? 28 : 16,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Column(
                  key: const ValueKey('exercise-catalog'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(wide ? 28 : 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEBF1FF), Color(0xFFF0EAFE)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE0DDF8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.library_books_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'THƯ VIỆN LUYỆN NÓI',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Chọn bài luyện hôm nay',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tìm câu hoặc nhóm âm bạn muốn cải thiện. Chọn một bài để nghe mẫu, ghi âm và nhận phản hồi.',
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: [
                              _LibraryHint(
                                icon: Icons.auto_stories_rounded,
                                label: '${widget.exercises.length} bài luyện',
                              ),
                              const _LibraryHint(
                                icon: Icons.hearing_rounded,
                                label: 'Nghe mẫu & luyện nói',
                              ),
                              const _LibraryHint(
                                icon: Icons.insights_rounded,
                                label: 'Phản hồi từng âm',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, filters) {
                        final search = TextField(
                          key: const ValueKey('exercise-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Tìm bài luyện',
                            hintText: 'Câu tiếng Anh, IPA hoặc nhóm âm…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Xóa tìm kiếm',
                                    onPressed: () => setState(_search.clear),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            fillColor: Colors.white,
                          ),
                        );
                        final category = DropdownButtonFormField<String>(
                          key: ValueKey('exercise-category-$_category'),
                          initialValue: _category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Nhóm âm',
                            prefixIcon: Icon(Icons.tune_rounded),
                            fillColor: Colors.white,
                          ),
                          items: [
                            for (final value in categories)
                              DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _category = value ?? 'Tất cả'),
                        );
                        return filters.maxWidth >= 700
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: search),
                                  const SizedBox(width: 16),
                                  SizedBox(width: 280, child: category),
                                ],
                              )
                            : Column(
                                children: [
                                  search,
                                  const SizedBox(height: 16),
                                  category,
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Danh sách bài luyện',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${filtered.length} / ${widget.exercises.length} bài',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 44,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không có bài luyện phù hợp',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Thử từ khóa khác hoặc chọn lại nhóm âm.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Xem tất cả bài luyện'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, grid) {
                          final columns = grid.maxWidth >= 1080
                              ? 3
                              : grid.maxWidth >= 640
                              ? 2
                              : 1;
                          final width =
                              (grid.maxWidth - (columns - 1) * 16) / columns;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final exercise in filtered)
                                SizedBox(
                                  width: width,
                                  child: ExerciseCard(
                                    key: ValueKey('exercise-${exercise.id}'),
                                    exerciseDetail: exercise,
                                    onTap: () => widget.onSelect(exercise),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryHint extends StatelessWidget {
  const _LibraryHint({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}
