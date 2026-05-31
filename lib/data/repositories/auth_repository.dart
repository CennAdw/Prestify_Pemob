import '../../core/services/api_service.dart';
import '../models/user_model.dart';
import 'repository_helpers.dart';

class AuthRepository {
  const AuthRepository({this.apiService = const ApiService()});

  final ApiService apiService;

  Future<UserModel> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final data = await apiService.post('auth/login.php', {
      'email': email,
      'password': password,
      'role': role.apiValue,
    });
    final map = asMap(data);
    final userJson = asMap(map['user'] ?? map);
    return UserModel.fromJson(userJson);
  }
}
