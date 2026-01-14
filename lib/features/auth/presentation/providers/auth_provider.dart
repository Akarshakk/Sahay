import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

/// Repository Provider
@riverpod
IAuthRepository authRepository(AuthRepositoryRef ref) {
  return MockAuthRepository();
}

/// Auth State Notifier
@riverpod
class AuthController extends _$AuthController {
  @override
  User? build() {
    return null; // Initial state: not logged in
  }

  Future<User?> login(String phone) async {
    final repository = ref.read(authRepositoryProvider);
    
    try {
      final user = await repository.login(phone);
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
