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
    final client = SupabaseService.client;
    final data = await client
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

    if (role == UserRole.lecturer) {
      final lecturerData = await client
          .from('lecturers')
          .select()
          .eq('email', email)
          .limit(1);
      final lecturers = asMapList(lecturerData);
      if (lecturers.isNotEmpty) {
        return UserModel.fromJson({
          ...user,
          ...lecturers.first,
          'lecturer_id': lecturers.first['id'],
          'role': role.apiValue,
          'email': user['email'],
        });
      }
    }

    return UserModel.fromJson(user);
  }
}