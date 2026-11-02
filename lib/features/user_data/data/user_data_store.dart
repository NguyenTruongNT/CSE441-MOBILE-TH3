import 'dart:convert';

/// Abstraction lưu trữ nội bộ của module User Data.
///
/// Repository chỉ phụ thuộc vào interface này, không phụ thuộc trực tiếp
/// vào SharedPreferences hoặc công nghệ lưu trữ cụ thể.
abstract interface class UserDataStore {
  /// Đọc chuỗi JSON đã lưu.
  ///
  /// Trả về null nếu module chưa có dữ liệu.
  Future<String?> read();

  /// Ghi toàn bộ JSON của module bằng một thao tác.
  Future<void> write(String value);

  /// Xóa toàn bộ dữ liệu của module.
  Future<void> clear();
}

/// Store trong bộ nhớ dùng cho unit test và demo độc lập.
class MemoryUserDataStore implements UserDataStore {
  MemoryUserDataStore({String? initialValue}) : _value = initialValue;

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    // Xác nhận nội dung là JSON hợp lệ trước khi lưu.
    jsonDecode(value);
    _value = value;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}
