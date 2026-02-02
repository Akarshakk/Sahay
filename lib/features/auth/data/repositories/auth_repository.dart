import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';

import '../../../../core/services/api_service.dart';

/// Authentication Repository Interface
abstract class IAuthRepository {
  Future<User?> login(String phone, String password);
  Future<User?> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String address,
    required String profession,
    required String dob,
    // New fields
    String? registeredArea,
    String? registeredAreaId,
    String? identityDocumentUrl,
    String? identityDocumentType,
    String? authorityCode,
    String? department,
    String? registrationNumber,
  });
  Future<void> logout();
  User? getCurrentUser();
  Future<void> sendEmailOtp(String email);
  Future<void> verifyEmailOtp(String email, String otp);
  Future<User?> updateProfile(Map<String, dynamic> data);
}

/// Real Authentication Repository
class AuthRepository implements IAuthRepository {
  final ApiService _apiService;
  User? _currentUser;

  AuthRepository(this._apiService);

  @override
  Future<void> sendEmailOtp(String email) async {
    await _apiService.sendEmailOtp(email);
  }

  @override
  Future<void> verifyEmailOtp(String email, String otp) async {
    await _apiService.verifyEmailOtp(email, otp);
  }

  @override
  Future<User?> updateProfile(Map<String, dynamic> data) async {
    try {
      final userData = await _apiService.updateProfile(data);
      
      // Backend returns the User object directly
      _currentUser = User(
        id: userData['id']?.toString() ?? _currentUser?.id ?? '',
        name: userData['fullName'] ?? _currentUser?.name ?? 'User',
        phone: userData['phone'] ?? _currentUser?.phone ?? '',
        role: _parseRole(userData['role'] ?? 'citizen'),
        email: userData['email'] ?? _currentUser?.email,
        state: userData['registeredArea'] ?? userData['address'] ?? _currentUser?.state,
        profession: userData['profession'] ?? _currentUser?.profession,
        address: userData['address'] ?? _currentUser?.address,
        registeredArea: userData['registeredArea'] ?? _currentUser?.registeredArea,
        registeredAreaId: userData['registeredAreaId'] ?? _currentUser?.registeredAreaId,
        identityDocumentUrl: userData['identityDocumentUrl'] ?? _currentUser?.identityDocumentUrl,
        identityDocumentType: userData['identityDocumentType'] ?? _currentUser?.identityDocumentType,
        authorityCode: userData['authorityCode'] ?? _currentUser?.authorityCode,
        department: userData['department'] ?? _currentUser?.department,
        registrationNumber: userData['registrationNumber'] ?? _currentUser?.registrationNumber,
        emergencyContacts: _mapContacts(userData['emergencyContacts']) ?? _currentUser?.emergencyContacts,
      );
      
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User?> login(String phone, String password) async {
    try {
      final response = await _apiService.login({
        'phone': phone,
        'password': password,
      });

      // Backend returns: { user: {...}, accessToken: "..." }
      if (response['user'] != null) {
        final userData = response['user'] as Map<String, dynamic>;
        _currentUser = User(
          id: userData['id']?.toString() ?? '',
          name: userData['fullName'] ?? 'User',
          phone: userData['phone'] ?? '',
          role: _parseRole(userData['role'] ?? 'citizen'),
          email: userData['email'],
          state: userData['state'],
          profession: userData['profession'],
          address: userData['address'],
          registeredArea: userData['registeredArea'],
          identityDocumentUrl: userData['identityDocumentUrl'],
          identityDocumentType: userData['identityDocumentType'],
          emergencyContacts: _mapContacts(userData['emergencyContacts']),
        );

        if (response['accessToken'] != null) {
          _apiService.setAuthToken(response['accessToken']);
        }
        return _currentUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User?> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String address,
    required String profession,
    required String dob,
    // New fields
    String? registeredArea,
    String? registeredAreaId,
    String? identityDocumentUrl,
    String? identityDocumentType,
    String? authorityCode,
    String? department,
    String? registrationNumber,
  }) async {
    try {
      final requestData = {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role.toLowerCase(),
        'address': address,
        'profession': profession,
        'dob': dob,
      };

      // Add optional fields if present
      if (registeredArea != null) requestData['registeredArea'] = registeredArea;
      if (registeredAreaId != null) requestData['registeredAreaId'] = registeredAreaId;
      if (identityDocumentUrl != null) requestData['identityDocumentUrl'] = identityDocumentUrl;
      if (identityDocumentType != null) requestData['identityDocumentType'] = identityDocumentType;
      if (authorityCode != null) requestData['authorityCode'] = authorityCode;
      if (department != null) requestData['department'] = department;
      if (registrationNumber != null) requestData['registrationNumber'] = registrationNumber;

      final response = await _apiService.register(requestData);

      // Backend returns: { user: {...}, accessToken: "..." }
      if (response['user'] != null) {
        final userData = response['user'] as Map<String, dynamic>;
        // Backend returns fullName, but User model expects name
        _currentUser = User(
          id: userData['id']?.toString() ?? '',
          name: userData['fullName'] ?? fullName,
          phone: userData['phone'] ?? phone,
          role: _parseRole(userData['role'] ?? role),
          state: userData['registeredArea'] ?? address,
          emergencyContacts: _mapContacts(userData['emergencyContacts']),
        );

        if (response['accessToken'] != null) {
          _apiService.setAuthToken(response['accessToken']);
        }
        return _currentUser;
      }

      // Fallback: create user from input if backend didn't return user
      _currentUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fullName,
        phone: phone,
        role: _parseRole(role),
        state: registeredArea ?? address,
      );
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'volunteer':
        return UserRole.volunteer;
      case 'authority':
        return UserRole.authority;
      default:
        return UserRole.citizen;
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _apiService.clearAuthToken();
  }

  @override
  User? getCurrentUser() {
    return _currentUser;
  }

  List<EmergencyContact>? _mapContacts(dynamic list) {
    if (list == null || list is! List) return null;
    return list.map((e) => EmergencyContact(
      name: e['name'] ?? '',
      phone: e['phone'] ?? '',
      relation: e['relation'] ?? '',
    )).toList();
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});
