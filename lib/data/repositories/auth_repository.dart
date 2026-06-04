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
    final data = await _invokeMap(
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

  Future<UserModel> signUpWithPassword({
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
    );
    if (response.user == null) {
      throw const AuthRepositoryException(
        message: 'Akun gagal dibuat di Supabase Auth.',
      );
    }
    if (response.session == null) {
      throw const AuthRepositoryException(
        message:
            'Session pendaftaran tidak tersedia. Matikan Confirm email di Supabase karena verifikasi email menggunakan Resend.',
      );
    }
    return completeAuthenticatedLogin();
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

    // Role, provider, dan status verifikasi dibuat di database. Aplikasi tidak
    // pernah mengirim atau menentukan role pengguna.
    await client.rpc('ensure_current_user_profile');

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

  Future<UserModel> completeRegistration({
    required String name,
    required String academicIdentifier,
    required String faculty,
    required String studyProgram,
    required int? batchYear,
    required List<String> skills,
  }) async {
    await _invokeMap(
      'complete-registration',
      body: {
        'name': name.trim(),
        'academic_identifier': normalizeAcademicIdentifier(academicIdentifier),
        'faculty': faculty.trim(),
        'study_program': studyProgram.trim(),
        'batch_year': batchYear,
        'skills': skills,
      },
    );
    return completeAuthenticatedLogin();
  }

  Future<String> sendVerificationCode(String email) async {
    final data = await _invokeMap(
      'send-verification-code',
      body: {'email': email.trim().toLowerCase()},
    );
    return data['message']?.toString() ??
        'Kode verifikasi telah dikirim ke email UPI.';
  }

  Future<String> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final data = await _invokeMap(
      'verify-email-code',
      body: {'email': email.trim().toLowerCase(), 'code': code.trim()},
    );
    return data['message']?.toString() ?? 'Email berhasil diverifikasi.';
  }

  Future<void> signOut() {
    return SupabaseService.client.auth.signOut();
  }

  Future<Map<String, dynamic>> _invokeMap(
    String functionName, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        functionName,
        body: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const <String, dynamic>{};
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map) {
        throw AuthRepositoryException(
          message:
              details['message']?.toString() ??
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
