import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/app_enums.dart';

export '../enums/app_enums.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

// UserRole is imported from app_enums.dart

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String phone,
    required UserRole role,
    String? email,
    String? state,
    String? district,
    String? city,
    String? profession,
    String? address,
    String? registeredArea,
    String? registeredAreaId,
    String? identityDocumentUrl,
    String? identityDocumentType,
    String? authorityCode,
    String? department,
    String? registrationNumber,
    List<EmergencyContact>? emergencyContacts,
    @Default(true) bool isAvailable,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    required String name,
    required String phone,
    required String relation,
  }) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => _$EmergencyContactFromJson(json);
}

// Mock users for testing
class MockUsers {
  static const User citizen = User(
    id: 'user-citizen-001',
    name: 'Test Citizen',
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
