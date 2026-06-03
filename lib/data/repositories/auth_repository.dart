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

  Future<UserModel> completeGoogleLogin() async {
    final client = SupabaseService.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw StateError('Session Google belum tersedia.');
    }

    final email = authUser.email ?? '';
    if (email.isEmpty) {
      throw StateError('Akun Google tidak mengirim alamat email.');
    }

    // Role dibuat di database berdasarkan lecturer_allowlist. Aplikasi tidak
    // pernah mengirim atau menentukan role pengguna.
    await client.rpc('ensure_current_user_profile');

    final createdData = await client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .limit(1);
    final createdUsers = asMapList(createdData);
    if (createdUsers.isEmpty) {
      throw StateError('Profil pengguna gagal dibuat.');
    }

    return UserModel.fromJson(createdUsers.first);
  }

  Future<void> signOut() {
    return SupabaseService.client.auth.signOut();
  }
}
