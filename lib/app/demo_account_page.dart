import 'package:flutter/material.dart';

import '../core/contracts/models.dart';
import 'app_theme.dart';

class DemoAccountPage extends StatefulWidget {
  const DemoAccountPage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final UserProfile user;
  final Future<void> Function() onLogout;

  @override
  State<DemoAccountPage> createState() => _DemoAccountPageState();
}

class _DemoAccountPageState extends State<DemoAccountPage> {
  bool _leaving = false;

  Future<void> _logout() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa đăng xuất được. Hãy thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.user.displayName,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không gian luyện tập của bạn',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.account_circle_outlined),
                    title: Text('Tài khoản demo'),
                    subtitle: Text(
                      'Chọn tài khoản có sẵn để trải nghiệm và kiểm thử.',
                    ),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.devices_rounded),
                    title: Text('Dữ liệu trên thiết bị này'),
                    subtitle: Text(
                      'Mục tiêu và lịch sử riêng cho từng tài khoản. Không đồng bộ giữa các thiết bị.',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Múi giờ học tập'),
                    subtitle: Text(widget.user.timeZone),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Đăng xuất để chọn tài khoản khác. Lịch sử học vẫn được giữ trên thiết bị.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _leaving ? null : _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(_leaving ? 'Đang đăng xuất…' : 'Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
