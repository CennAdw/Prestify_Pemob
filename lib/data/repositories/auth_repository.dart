import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';
import 'repository_helpers.dart';

class AuthRepository {
  const AuthRepository();

  Future<bool> signInWithGoogle() {
    return SupabaseService.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: googleOAuthRedirectUrl,
      scopes: 'email profile',
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<UserModel> completeGoogleLogin({required UserRole role}) async {
    final client = SupabaseService.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw StateError('Session Google belum tersedia.');
    }

    final email = authUser.email ?? '';
    if (email.isEmpty) {
      throw StateError('Akun Google tidak mengirim alamat email.');
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final name = _displayName(metadata, email);
    final payload = {
      'id': authUser.id,
      'name': name,
      'email': email,
      'role': role.apiValue,
    };

    await client.from('users').upsert(payload, onConflict: 'id');

    if (role == UserRole.lecturer) {
      await client.from('lecturers').upsert({
        'id': authUser.id,
        'name': name,
        'email': email,
      }, onConflict: 'id');
    }

    final data = await client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .limit(1);
    final users = asMapList(data);
    if (users.isEmpty) {
      throw StateError('Profil pengguna gagal dibuat.');
    }

    return UserModel.fromJson(users.first);
  }

  Future<void> signOut() {
    return SupabaseService.client.auth.signOut();
  }

  String _displayName(Map<String, dynamic> metadata, String email) {
    final name =
        metadata['full_name'] ?? metadata['name'] ?? metadata['display_name'];
    final text = name?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
    return email.split('@').first;
  }
}
