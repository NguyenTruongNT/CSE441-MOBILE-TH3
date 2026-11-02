import 'package:flutter/material.dart';

class ProfileFormResult {
  const ProfileFormResult({required this.displayName, required this.timeZone});

  final String displayName;
  final String timeZone;
}

class ProfileFormDialog extends StatefulWidget {
  const ProfileFormDialog({
    super.key,
    this.initialDisplayName = '',
    this.initialTimeZone = 'Asia/Ho_Chi_Minh',
    this.isEditing = false,
  });

  final String initialDisplayName;
  final String initialTimeZone;
  final bool isEditing;

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _timeZoneController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialDisplayName);

    _timeZoneController = TextEditingController(text: widget.initialTimeZone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ProfileFormResult(
        displayName: _nameController.text.trim(),
        timeZone: _timeZoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Chỉnh sửa hồ sơ' : 'Tạo hồ sơ mới'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('profile-display-name-field'),
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  hintText: 'Ví dụ: Vũ Tuấn Khanh',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên hồ sơ.';
                  }

                  if (value.trim().length > 80) {
                    return 'Tên hồ sơ không được vượt quá 80 ký tự.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('profile-time-zone-field'),
                controller: _timeZoneController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Múi giờ',
                  hintText: 'Asia/Ho_Chi_Minh',
                  prefixIcon: Icon(Icons.public_rounded),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập múi giờ.';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Múi giờ được dùng để xác định ngày học, '
                  'streak và thời gian nhắc học.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          key: const ValueKey('profile-form-submit-button'),
          onPressed: _submit,
          icon: Icon(
            widget.isEditing
                ? Icons.save_outlined
                : Icons.person_add_alt_1_rounded,
          ),
          label: Text(widget.isEditing ? 'Lưu thay đổi' : 'Tạo hồ sơ'),
        ),
      ],
    );
  }
}
