import 'package:flutter/material.dart';

import 'app_theme.dart';

const navigationLabels = ['Tiến độ', 'Luyện nói', 'Lịch sử', 'Tài khoản'];
const navigationIcons = [
  Icons.grid_view_rounded,
  Icons.mic_rounded,
  Icons.history_rounded,
  Icons.person_outline_rounded,
];
const navigationKeys = [
  ValueKey('nav-progress'),
  ValueKey('nav-pronunciation'),
  ValueKey('nav-history'),
  ValueKey('nav-profile'),
];

class LearningBrand extends StatelessWidget {
  const LearningBrand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppTheme.violet.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white,
          size: 27,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 12),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'English AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'NÓI TỐT HƠN MỖI NGÀY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class LearningSidebar extends StatelessWidget {
  const LearningSidebar({
    super.key,
    required this.expanded,
    required this.selectedIndex,
    required this.onToggle,
    required this.onSelect,
    this.accountName,
    this.onLogout,
    this.loggingOut = false,
  });
  final bool expanded;
  final int selectedIndex;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;
  final String? accountName;
  final VoidCallback? onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('navigation-sidebar'),
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    width: expanded ? 272 : 96,
    margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE7EAF4)),
      boxShadow: [
        BoxShadow(
          color: AppTheme.ink.withValues(alpha: 0.035),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: expanded ? 270 : 94,
        maxWidth: expanded ? 270 : 94,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 22 : 16,
                24,
                expanded ? 18 : 16,
                12,
              ),
              child: LearningBrand(compact: !expanded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (expanded)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          'KHÔNG GIAN HỌC TẬP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.muted,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    key: const ValueKey('sidebar-toggle'),
                    tooltip: expanded
                        ? 'Thu gọn thanh bên'
                        : 'Mở rộng thanh bên',
                    onPressed: onToggle,
                    icon: Icon(
                      expanded
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                    ),
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                children: [
                  for (var index = 0; index < 3; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SidebarItem(
                        key: navigationKeys[index],
                        icon: navigationIcons[index],
                        label: navigationLabels[index],
                        active: selectedIndex == index,
                        expanded: expanded,
                        onTap: () => onSelect(index),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Divider(height: 24),
                  _SidebarItem(
                    key: navigationKeys[3],
                    icon: Icons.person_outline_rounded,
                    label: accountName ?? 'Tài khoản',
                    subtitle: 'Tài khoản demo',
                    active: selectedIndex == 3,
                    expanded: expanded,
                    onTap: () => onSelect(3),
                  ),
                  if (onLogout != null || loggingOut) ...[
                    const SizedBox(height: 8),
                    Tooltip(
                      message: 'Đăng xuất',
                      child: TextButton(
                        onPressed: loggingOut ? null : onLogout,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.muted,
                          minimumSize: const Size(48, 46),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (loggingOut)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(Icons.logout_rounded, size: 19),
                            if (expanded) ...[
                              const SizedBox(width: 10),
                              const Text('Đăng xuất'),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.expanded,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: expanded ? '' : label,
    child: Semantics(
      button: true,
      selected: active,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            gradient: active ? AppTheme.accentGradient : null,
            color: active ? null : const Color(0xFFF7F8FD),
            borderRadius: BorderRadius.circular(17),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.violet.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 16 : 0,
                  vertical: 17,
                ),
                child: Row(
                  mainAxisAlignment: expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 23,
                      color: active ? Colors.white : AppTheme.muted,
                    ),
                    if (expanded) ...[
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active ? Colors.white : AppTheme.ink,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: active
                                      ? Colors.white70
                                      : AppTheme.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (active)
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class LearningTopBar extends StatelessWidget {
  const LearningTopBar({
    super.key,
    required this.title,
    required this.description,
    required this.wide,
    required this.onAccount,
    this.accountName,
  });
  final String title;
  final String description;
  final bool wide;
  final VoidCallback onAccount;
  final String? accountName;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      wide ? 24 : 20,
      wide ? 25 : 18,
      wide ? 32 : 20,
      wide ? 16 : 12,
    ),
    child: Row(
      children: [
        if (!wide) ...[
          const LearningBrand(compact: true),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wide ? 'HÀNH TRÌNH CỦA BẠN' : 'ENGLISH AI',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: wide ? 25 : 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),
              if (wide) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Tài khoản',
          child: InkWell(
            key: wide ? const ValueKey('header-account') : navigationKeys[3],
            onTap: onAccount,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE9FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.violet,
                      size: 24,
                    ),
                  ),
                  if (wide && accountName != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      accountName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Three learning destinations; the account remains accessible in the top bar.
class LearningBottomBar extends StatelessWidget {
  const LearningBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('navigation-bottom'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      boxShadow: [
        BoxShadow(
          color: AppTheme.ink.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            for (var index = 0; index < 3; index++)
              Expanded(
                child: Semantics(
                  key: navigationKeys[index],
                  button: true,
                  selected: selectedIndex == index,
                  label: navigationLabels[index],
                  onTap: () => onSelect(index),
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: () => onSelect(index),
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index == 1)
                              Container(
                                width: 54,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(17),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.violet.withValues(
                                        alpha: selectedIndex == 1 ? 0.35 : 0.18,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 27,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedIndex == index
                                      ? const Color(0xFFECE9FF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  navigationIcons[index],
                                  color: selectedIndex == index
                                      ? AppTheme.violet
                                      : AppTheme.muted,
                                  size: 24,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              navigationLabels[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedIndex == index
                                    ? AppTheme.violet
                                    : AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
