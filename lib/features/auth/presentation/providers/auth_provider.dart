import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// Removed explicit authRepository provider since it's now in the repository file

/// Auth State Notifier
@riverpod
class AuthController extends _$AuthController {
  @override
  User? build() {
    return null; // Initial state: not logged in
  }

  Future<User?> login(String phone, String password) async {
    final repository = ref.read(authRepositoryProvider);

    try {
      final user = await repository.login(phone, password);
      state = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String address,
    required String profession,
    required DateTime dob,
  }) async {
    final repository = ref.read(authRepositoryProvider);

    try {
      final user = await repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
        address: address,
        profession: profession,
        dob: dob.toIso8601String(),
      );
      state = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = null;
  }

  bool get isLoggedIn => state != null;

  UserRole? get userRole => state?.role;
}
