import 'dart:async';
import '../../../../core/models/user_model.dart';

/// Authentication Repository Interface
abstract class IAuthRepository {
  Future<User?> login(String phone);
  Future<void> logout();
  User? getCurrentUser();
}

/// Mock Authentication Repository
class MockAuthRepository implements IAuthRepository {
  User? _currentUser;

  @override
  Future<User?> login(String phone) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication logic
    switch (phone) {
      case '1111111111':
        _currentUser = MockUsers.citizen;
        return _currentUser;
      case '2222222222':
        _currentUser = MockUsers.volunteer;
        return _currentUser;
      case '3333333333':
        _currentUser = MockUsers.authority;
        return _currentUser;
      default:
        throw Exception('Invalid credentials. Try: 1111111111 (Citizen), 2222222222 (Volunteer), or 3333333333 (Authority)');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  User? getCurrentUser() {
    return _currentUser;
  }
}
