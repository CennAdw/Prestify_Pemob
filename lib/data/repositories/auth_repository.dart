import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/auth_config.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';
import 'repository_helpers.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException({required this.message, this.code, this.email});

  final String message;
  final String? code;
  final String? email;

  @override
  String toString() => message;
}

class AuthRepository {
  const AuthRepository();

  Future<bool> signInWithGoogle() {
    return SupabaseService.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: googleOAuthRedirectUrl,
      scopes: 'email profile',
      queryParams: const {'prompt': 'select_account', 'hd': allowedEmailDomain},
    );
  }

  Future<UserModel> signInWithNim({
    required String identifier,
    required String password,
  }) async {
    final data = await _invokeMapAnon(
      'login-with-nim',
      body: {
        'identifier': normalizeAcademicIdentifier(identifier),
        'password': password,
      },
    );
    final refreshToken = data['refresh_token']?.toString() ?? '';
    final accessToken = data['access_token']?.toString() ?? '';
    if (refreshToken.isEmpty || accessToken.isEmpty) {
      throw const AuthRepositoryException(
        message: 'Session login tidak diterima dari server.',
      );
    }

    await SupabaseService.client.auth.setSession(
      refreshToken,
      accessToken: accessToken,
    );
    return completeAuthenticatedLogin();
  }

  // ✅ Return void — tidak butuh session, tidak panggil completeAuthenticatedLogin
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isAllowedUpiEmail(normalizedEmail)) {
      throw const AuthRepositoryException(
        code: 'INVALID_EMAIL_DOMAIN',
        message: 'Pendaftaran hanya menerima email @upi.edu.',
      );
    }

    final response = await SupabaseService.client.auth.signUp(
      email: normalizedEmail,
      password: password,
      emailRedirectTo: emailVerificationRedirectUrl,
    );

    if (response.user == null) {
      throw const AuthRepositoryException(
        message: 'Akun gagal dibuat di Supabase Auth.',
      );
    }
    // Session akan null karena Confirm Email ON — itu normal
    // completeRegistration dan sendVerificationCode dipanggil setelahnya
  }

  Future<UserModel> completeAuthenticatedLogin() async {
    final client = SupabaseService.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw const AuthRepositoryException(
        message: 'Session autentikasi belum tersedia.',
      );
    }

    final email = authUser.email?.trim().toLowerCase() ?? '';
    if (!isAllowedUpiEmail(email)) {
      await client.auth.signOut();
      throw const AuthRepositoryException(
        code: 'INVALID_EMAIL_DOMAIN',
        message: 'Prestify hanya menerima akun email @upi.edu.',
      );
    }

    await client.rpc('ensure_current_user_profile'); // ✅ hanya sekali

    final data = await client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .limit(1);
    final users = asMapList(data);
    if (users.isEmpty) {
      throw const AuthRepositoryException(
        message: 'Profil pengguna gagal dibuat.',
      );
    }

    return UserModel.fromJson(users.first);
  }

  // ✅ Return void, tambah param email, pakai _invokeMapAnon
  Future<void> completeRegistration({
    required String email,
    required String name,
    required String academicIdentifier,
    required String faculty,
    required String studyProgram,
    required int? batchYear,
    required List<String> skills,
  }) async {
    await _invokeMapAnon(
      'complete-registration',
      body: {
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'academic_identifier': normalizeAcademicIdentifier(academicIdentifier),
        'faculty': faculty.trim(),
        'study_program': studyProgram.trim(),
        'batch_year': batchYear,
        'skills': skills,
      },
    );
  }

  Future<void> signOut() {
    return SupabaseService.client.auth.signOut();
  }

  // Untuk call yang butuh session (login, dsb)
  Future<Map<String, dynamic>> _invokeMap(
    String functionName, {
    required Map<String, dynamic> body,
  }) async {
    final token =
        SupabaseService.client.auth.currentSession?.accessToken;
    return _invoke(functionName, body: body, token: token);
  }

  // ✅ Untuk call saat register — tidak ada session, pakai anon key
  Future<Map<String, dynamic>> _invokeMapAnon(
    String functionName, {
    required Map<String, dynamic> body,
  }) async {
    return _invoke(functionName, body: body, token: null);
  }

    Future<Map<String, dynamic>> _invoke(
      String functionName, {
      required Map<String, dynamic> body,
      required String? token,
    }) async {
      try {
        final headers = <String, String>{};

        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        final response = await SupabaseService.client.functions.invoke(
          functionName,
          body: body,
          headers: headers,
        );

        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return const <String, dynamic>{};
      } on FunctionException catch (error) {
        final details = error.details;
        if (details is Map) {
          throw AuthRepositoryException(
            message: details['message']?.toString() ??
                'Request autentikasi gagal (${error.status}).',
            code: details['code']?.toString(),
            email: details['email']?.toString(),
          );
        }
        throw AuthRepositoryException(
          message: 'Request autentikasi gagal (${error.status}): $details',
        );
      }
    }
}