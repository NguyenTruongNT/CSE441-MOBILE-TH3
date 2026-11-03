import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/shared/app_states.dart';
import '../../../core/contracts/contracts.dart';
import 'profile_form_dialog.dart';

typedef ProfileIdFactory = String Function();
typedef ProfileClock = DateTime Function();

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userRepository,
    this.idFactory,
    this.clock,
  });

  final UserRepository userRepository;

  /// Cho phép test tạo ID cố định.
  final ProfileIdFactory? idFactory;

  /// Cho phép test thời điểm tạo hồ sơ.
  final ProfileClock? clock;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<UserProfile> _profiles = const <UserProfile>[];
  UserProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfiles());
  }

  Future<void> _loadProfiles({bool showLoading = true}) async {
    if (!mounted) {
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<UserProfile> profiles = await widget.userRepository
          .listProfiles();

      final UserProfile? selectedProfile = await widget.userRepository
          .getSelectedProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;
        _selectedProfile = selectedProfile;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách hồ sơ: $error';
      });
    }
  }

  Future<void> _createProfile() async {
    final ProfileFormResult? result = await showDialog<ProfileFormResult>(
      context: context,
      builder: (BuildContext context) {
        return const ProfileFormDialog();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final DateTime createdAt = (widget.clock ?? DateTime.now)().toUtc();

    final String id =
        widget.idFactory?.call() ?? 'user-${createdAt.microsecondsSinceEpoch}';

    final UserProfile profile = UserProfile(
      id: id,
      displayName: result.displayName,
      timeZone: result.timeZone,
      createdAt: createdAt,
    );

    await _saveProfile(
      profile: profile,
      shouldSelect: true,
      successMessage: 'Đã tạo hồ sơ mới.',
    );
  }

  Future<void> _editProfile(UserProfile profile) async {
    final ProfileFormResult? result = await showDialog<ProfileFormResult>(
      context: context,
      builder: (BuildContext context) {
        return ProfileFormDialog(
          initialDisplayName: profile.displayName,
          initialTimeZone: profile.timeZone,
          isEditing: true,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final UserProfile updatedProfile = UserProfile(
      id: profile.id,
      displayName: result.displayName,
      timeZone: result.timeZone,
      createdAt: profile.createdAt,
    );

    await _saveProfile(
      profile: updatedProfile,
      shouldSelect: _selectedProfile?.id == profile.id,
      successMessage: 'Đã cập nhật hồ sơ.',
    );
  }

  Future<void> _saveProfile({
    required UserProfile profile,
    required bool shouldSelect,
    required String successMessage,
  }) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.userRepository.saveProfile(profile);

      if (shouldSelect) {
        await widget.userRepository.selectProfile(profile.id);
      }

      await _loadProfiles(showLoading: false);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Không thể lưu hồ sơ: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectProfile(UserProfile profile) async {
    if (_isSaving || profile.id == _selectedProfile?.id) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.userRepository.selectProfile(profile.id);

      await _loadProfiles(showLoading: false);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Đã chọn hồ sơ ${profile.displayName}.')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Không thể chọn hồ sơ: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingState(message: 'Đang tải hồ sơ…');
    }

    if (_errorMessage != null) {
      return AppMessageState(
        title: 'Lỗi tải hồ sơ',
        message: _errorMessage!,
        icon: Icons.error_outline_rounded,
        onRetry: _loadProfiles,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 800;

        return RefreshIndicator(
          onRefresh: () {
            return _loadProfiles(showLoading: false);
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
                    if (_profiles.isEmpty)
                      _buildEmptyState(context)
                    else
                      _buildProfileList(context, isWide: isWide),
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

    final Widget titleArea = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hồ sơ người học',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quản lý hồ sơ cục bộ và tách riêng '
          'lịch sử học tập cho từng người.',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );

    final Widget createButton = FilledButton.icon(
      key: const ValueKey('create-profile-button'),
      onPressed: _isSaving ? null : _createProfile,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: const Text('Tạo hồ sơ'),
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isWide
            ? Row(
                children: [
                  Expanded(child: titleArea),
                  const SizedBox(width: 24),
                  createButton,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [titleArea, const SizedBox(height: 20), createButton],
              ),
      ),
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
              Icons.person_add_alt_1_rounded,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có hồ sơ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tạo hồ sơ đầu tiên để lưu lịch sử, '
              'cài đặt và kết quả luyện phát âm.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _createProfile,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo hồ sơ đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileList(BuildContext context, {required bool isWide}) {
    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        itemCount: _profiles.length,
        itemBuilder: (BuildContext context, int index) {
          final UserProfile profile = _profiles[index];

          return _ProfileCard(
            profile: profile,
            isSelected: profile.id == _selectedProfile?.id,
            isBusy: _isSaving,
            onSelect: () {
              unawaited(_selectProfile(profile));
            },
            onEdit: () {
              unawaited(_editProfile(profile));
            },
          );
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _profiles.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        final UserProfile profile = _profiles[index];

        return _ProfileCard(
          profile: profile,
          isSelected: profile.id == _selectedProfile?.id,
          isBusy: _isSaving,
          onSelect: () {
            unawaited(_selectProfile(profile));
          },
          onEdit: () {
            unawaited(_editProfile(profile));
          },
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isSelected,
    required this.isBusy,
    required this.onSelect,
    required this.onEdit,
  });

  final UserProfile profile;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      key: ValueKey('profile-card-${profile.id}'),
      elevation: 0,
      color: isSelected
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primaryContainer,
              foregroundColor: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onPrimaryContainer,
              child: Text(
                _profileInitials(profile.displayName),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle_rounded, size: 21),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Múi giờ: ${profile.timeZone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày tạo: '
                    '${_formatDate(profile.createdAt)}',
                  ),

                  // Không dùng Spacer trong Card mobile vì
                  // chiều cao của Card không bị giới hạn.
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: ValueKey('edit-profile-${profile.id}'),
                          onPressed: isBusy ? null : onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Chỉnh sửa'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          key: ValueKey('select-profile-${profile.id}'),
                          onPressed: isBusy || isSelected ? null : onSelect,
                          icon: Icon(
                            isSelected
                                ? Icons.check_rounded
                                : Icons.person_outline_rounded,
                          ),
                          label: Text(isSelected ? 'Đang chọn' : 'Chọn'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _profileInitials(String displayName) {
  final List<String> words = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return '?';
  }

  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words.first.substring(0, 1)}'
          '${words.last.substring(0, 1)}'
      .toUpperCase();
}

String _formatDate(DateTime value) {
  final DateTime localValue = value.toLocal();

  final String day = localValue.day.toString().padLeft(2, '0');

  final String month = localValue.month.toString().padLeft(2, '0');

  return '$day/$month/${localValue.year}';
}
