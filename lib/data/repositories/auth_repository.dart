import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';
import 'repository_helpers.dart';

class AuthRepository {
  const AuthRepository();

  Future<UserModel> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final data = await SupabaseService.client
        .from('users')
        .select()
        .eq('email', email)
        .eq('role', role.apiValue)
        .limit(1);

    final users = asMapList(data);
    if (users.isEmpty) {
      throw StateError('Akun tidak ditemukan.');
    }

    final user = users.first;
    if ((user['password'] ?? '').toString() != password) {
      throw StateError('Password salah.');
    }

    return UserModel.fromJson(user);
  }
}
