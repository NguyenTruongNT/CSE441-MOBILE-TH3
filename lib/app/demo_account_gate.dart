import 'package:flutter/material.dart';

import '../core/contracts/contracts.dart';
import 'app_theme.dart';

/// Demo entry point. Account selection is not password authentication.
class DemoAccountGate extends StatefulWidget {
  const DemoAccountGate({
    super.key,
    required this.users,
    required this.buildHome,
    this.initialize,
  });
  final UserRepository users;
  final Widget Function(UserProfile user, VoidCallback logout) buildHome;
  final Future<void> Function()? initialize;

  @override
  State<DemoAccountGate> createState() => _DemoAccountGateState();
}

class _DemoAccountGateState extends State<DemoAccountGate> {
  late Future<List<UserProfile>> _accounts;
  UserProfile? _active;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accounts = _prepareAccounts();
  }

  Future<List<UserProfile>> _prepareAccounts() async {
    await widget.initialize?.call();
    final existing = await widget.users.listProfiles();
    for (var i = 1; i <= 4; i++) {
      final id = 'demo-learner-$i';
      if (existing.any((user) => user.id == id)) continue;
      await widget.users.saveProfile(
        UserProfile(
          id: id,
          displayName: 'Học viên $i',
          createdAt: DateTime.utc(2026, 11, 3),
        ),
      );
    }
    return widget.users.listProfiles();
  }

  Future<void> _enter(UserProfile user) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.users.selectProfile(user.id);
      if (mounted) setState(() => _active = user);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không mở được tài khoản. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    if (active != null) {
      return widget.buildHome(active, () => setState(() => _active = null));
    }
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'English AI',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Luyện nói mỗi ngày. Tự tin qua từng âm.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Chọn tài khoản để bắt đầu',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tài khoản demo có sẵn. Lịch sử và mục tiêu được lưu riêng trên thiết bị này.',
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<UserProfile>>(
                    future: _accounts,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            const Text('Không tải được tài khoản.'),
                            TextButton(
                              onPressed: () => setState(
                                () => _accounts = _prepareAccounts(),
                              ),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Column(
                        children: [
                          for (final user in snapshot.data!)
                            Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  child: Text(user.displayName.split(' ').last),
                                ),
                                title: Text(user.displayName),
                                subtitle: const Text('Tài khoản demo'),
                                trailing: const Icon(
                                  Icons.arrow_forward_rounded,
                                ),
                                onTap: _busy ? null : () => _enter(user),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
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
