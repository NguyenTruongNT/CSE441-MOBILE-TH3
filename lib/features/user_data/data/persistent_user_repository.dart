import '../../../core/contracts/contracts.dart';
import 'user_data_schema.dart';
import 'user_data_serializers.dart';
import 'user_data_store.dart';

/// Triển khai [UserRepository] bằng [UserDataStore].
///
/// Repository hỗ trợ:
/// - Tạo hồ sơ mới.
/// - Cập nhật hồ sơ theo ID.
/// - Liệt kê hồ sơ.
/// - Chọn hồ sơ hiện tại.
/// - Duy trì dữ liệu thông qua store được truyền vào.
class PersistentUserRepository implements UserRepository {
  PersistentUserRepository({required UserDataStore store})
    : _documentManager = UserDataDocumentManager(store);

  final UserDataDocumentManager _documentManager;

  @override
  Future<List<UserProfile>> listProfiles() async {
    final UserDataDocument document = await _documentManager.read();

    final List<UserProfile> profiles = document.users.map((
      Map<String, Object?> json,
    ) {
      return UserDataSerializers.userProfileFromJson(json);
    }).toList();

    profiles.sort((UserProfile first, UserProfile second) {
      final int createdComparison = first.createdAt.compareTo(second.createdAt);

      if (createdComparison != 0) {
        return createdComparison;
      }

      return first.displayName.toLowerCase().compareTo(
        second.displayName.toLowerCase(),
      );
    });

    return List<UserProfile>.unmodifiable(profiles);
  }

  @override
  Future<UserProfile?> getSelectedProfile() async {
    final UserDataDocument document = await _documentManager.read();

    final String? selectedUserId = document.selectedUserId;

    if (selectedUserId == null) {
      return null;
    }

    for (final Map<String, Object?> json in document.users) {
      final UserProfile profile = UserDataSerializers.userProfileFromJson(json);

      if (profile.id == selectedUserId) {
        return profile;
      }
    }

    throw AppFailure(
      AppFailureCode.storage,
      'Hồ sơ được chọn không còn tồn tại: '
      '$selectedUserId.',
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _validateProfile(profile);

    final UserDataDocument document = await _documentManager.read();

    final int existingIndex = document.users.indexWhere((
      Map<String, Object?> json,
    ) {
      return json['id'] == profile.id;
    });

    final Map<String, Object?> profileJson =
        UserDataSerializers.userProfileToJson(profile);

    if (existingIndex >= 0) {
      document.users[existingIndex] = profileJson;
    } else {
      document.users.add(profileJson);
    }

    await _documentManager.write(document);
  }

  @override
  Future<void> selectProfile(String userId) async {
    final String normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'ID hồ sơ không được để trống.',
      );
    }

    final UserDataDocument document = await _documentManager.read();

    final bool profileExists = document.users.any((Map<String, Object?> json) {
      return json['id'] == normalizedUserId;
    });

    if (!profileExists) {
      throw AppFailure(
        AppFailureCode.storage,
        'Không tìm thấy hồ sơ: '
        '$normalizedUserId.',
      );
    }

    if (document.selectedUserId == normalizedUserId) {
      return;
    }

    document.selectedUserId = normalizedUserId;

    await _documentManager.write(document);
  }

  void _validateProfile(UserProfile profile) {
    if (profile.id.trim().isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'ID hồ sơ không được để trống.',
      );
    }

    if (profile.displayName.trim().isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Tên hồ sơ không được để trống.',
      );
    }

    if (profile.timeZone.trim().isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Múi giờ hồ sơ không được để trống.',
      );
    }
  }
}
