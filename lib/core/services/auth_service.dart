import '../../data/models/user_model.dart';

class AuthService {
  UserModel? _cachedUser;

  Future<void> saveUser(UserModel user) async => _cachedUser = user;

  Future<UserModel?> getSavedUser() async => _cachedUser;

  Future<void> clear() async => _cachedUser = null;
}
