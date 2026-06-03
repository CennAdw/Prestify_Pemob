import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isCompletingLogin = false;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.isReady) {
      _authSubscription = SupabaseService.authStateChanges.listen((state) {
        if (state.session != null && state.event != AuthChangeEvent.signedOut) {
          _completeGoogleLogin();
        }
      });

      if (SupabaseService.client.auth.currentSession != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _completeGoogleLogin();
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final state = AppStateScope.of(context);
    final result = await state.signInWithGoogle();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _completeGoogleLogin() async {
    if (_isCompletingLogin) return;
    _isCompletingLogin = true;
    final state = AppStateScope.of(context);
    final result = await state.completeGoogleLogin();
    _isCompletingLogin = false;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (!result.success) return;
    Navigator.pushNamedAndRemoveUntil(context, result.route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/prestify_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 22),
              const Text('Masuk ke Prestify', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                'Login menggunakan akun Google untuk mengakses Prestify. Role akun ditentukan otomatis dari data terverifikasi.',
                style: AppTextStyles.body.copyWith(color: AppColors.textGray),
              ),
              const SizedBox(height: 24),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Akses Terverifikasi',
                                style: AppTextStyles.subtitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Akun dosen hanya dapat mengakses dashboard dosen jika emailnya sudah terdaftar oleh pengelola Prestify.',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: state.isAuthLoading
                          ? 'Menghubungkan...'
                          : 'Login menggunakan Google',
                      icon: Icons.login_rounded,
                      onPressed: state.isAuthLoading ? null : _signInWithGoogle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              CustomCard(
                color: AppColors.lightBlue,
                child: Text(
                  'Pastikan Google provider sudah aktif di Supabase dan redirect URL aplikasi sudah terdaftar.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
