import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/api_service.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// Storage key for persisted user session
const String _userSessionKey = 'user_session';
const String _authTokenKey = 'auth_token';

/// Auth State Notifier - keepAlive: true prevents state from resetting on navigation
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  User? build() {
    // Try to restore session on build
    _restoreSession();
    return null; // Initial state: not logged in (will be updated async)
  }

  /// Restore session from SharedPreferences
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userSessionKey);
      final token = prefs.getString(_authTokenKey);

      if (userJson != null) {
        // MIGRATION FIX: If user exists but token is missing/null, 
        // invalidate session to force re-login
        if (token == null) {
          print('DEBUG: Migration detected - User exists but token is null. Clearing session.');
          await _clearSession();
          state = null;
          return;
        }

        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userData);
        state = user;
        
        // SYNC TOKEN WITH API SERVICE
        ref.read(apiServiceProvider).setAuthToken(token);
        print('DEBUG: Session restored, token set in ApiService');
      }
    } catch (e) {
      // Session restoration failed, user will need to login again
      print('Session restore failed: $e');
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _saveSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userSessionKey, userJson);
      
      // Save token explicitly
      final token = ref.read(apiServiceProvider).authToken;
      if (token != null) {
        await prefs.setString(_authTokenKey, token);
      }
    } catch (e) {
      print('Session save failed: $e');
    }
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userSessionKey);
      await prefs.remove(_authTokenKey);
    } catch (e) {
      print('Session clear failed: $e');
    }
  }

  /// Check and restore session - call this on app startup
  Future<User?> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userSessionKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        state = User.fromJson(userData);
        return state;
      }
    } catch (e) {
      print('Session check failed: $e');
    }
    return null;
  }

  Future<User?> login(String phone, String password) async {
    final repository = ref.read(authRepositoryProvider);

    try {
      final user = await repository.login(phone, password);
      if (user != null) {
        state = user;
        await _saveSession(user); // Persist session
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailOtp(String email) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.sendEmailOtp(email);
  }

  Future<void> verifyEmailOtp(String email, String otp) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.verifyEmailOtp(email, otp);
  }

  Future<User?> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required dynamic role, // Can be UserRole or String
    required String address,
    required String profession,
    required DateTime dob,
    // New fields for area-based system
    String? registeredArea,
    String? registeredAreaId,
    // Document fields
    String? identityDocumentUrl,
    String? identityDocumentType,
    // Authority fields
    String? authorityCode,
    String? department,
    String? registrationNumber,
  }) async {
    final repository = ref.read(authRepositoryProvider);

    // Convert UserRole to string if needed
    final roleString = role is UserRole ? role.toString().split('.').last : role.toString();

    try {
      final user = await repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: roleString,
        address: address,
        profession: profession,
        dob: dob.toIso8601String(),
        registeredArea: registeredArea,
        registeredAreaId: registeredAreaId,
        identityDocumentUrl: identityDocumentUrl,
        identityDocumentType: identityDocumentType,
        authorityCode: authorityCode,
        department: department,
        registrationNumber: registrationNumber,
      );
      if (user != null) {
        state = user;
        await _saveSession(user); // Persist session
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> updateUser(Map<String, dynamic> data) async {
    final repository = ref.read(authRepositoryProvider);
    try {
      final updatedUser = await repository.updateProfile(data);
      if (updatedUser != null) {
        state = updatedUser;
        await _saveSession(updatedUser);
      }
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    await _clearSession(); // Clear persisted session
    state = null;
  }

  bool get isLoggedIn => state != null;

  UserRole? get userRole => state?.role;
}
