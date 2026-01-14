import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole {
  citizen,
  volunteer,
  authority,
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String phone,
    required UserRole role,
    String? state,
    @Default(true) bool isAvailable,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Mock users for testing
class MockUsers {
  static const User citizen = User(
    id: 'user-citizen-001',
    name: 'Akarshak Singh',
    phone: '1111111111',
    role: UserRole.citizen,
    state: 'Maharashtra',
  );

  static const User volunteer = User(
    id: 'user-volunteer-002',
    name: 'Volunteer Rahul',
    phone: '2222222222',
    role: UserRole.volunteer,
    state: 'Maharashtra',
  );

  static const User authority = User(
    id: 'user-authority-003',
    name: 'Authority Officer',
    phone: '3333333333',
    role: UserRole.authority,
    state: 'Maharashtra',
  );
}
