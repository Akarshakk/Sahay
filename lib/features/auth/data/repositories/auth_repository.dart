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
  });
  Future<void> logout();
  User? getCurrentUser();
}

/// Real Authentication Repository
class AuthRepository implements IAuthRepository {
  final ApiService _apiService;
  User? _currentUser;

  AuthRepository(this._apiService);

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
          state: null,
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
  }) async {
    try {
      final response = await _apiService.register({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role.toLowerCase(),
        'address': address,
        'profession': profession,
        'dob': dob,
      });

      // Backend returns: { user: {...}, accessToken: "..." }
      if (response['user'] != null) {
        final userData = response['user'] as Map<String, dynamic>;
        // Backend returns fullName, but User model expects name
        _currentUser = User(
          id: userData['id']?.toString() ?? '',
          name: userData['fullName'] ?? fullName,
          phone: userData['phone'] ?? phone,
          role: _parseRole(userData['role'] ?? role),
          state: address,
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
        state: address,
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
  }

  @override
  User? getCurrentUser() {
    return _currentUser;
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});
