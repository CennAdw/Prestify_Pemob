import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.student;
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
    final result = await state.signInWithGoogle(selectedRole: _selectedRole);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _completeGoogleLogin() async {
    if (_isCompletingLogin) return;
    _isCompletingLogin = true;
    final state = AppStateScope.of(context);
    final result = await state.completeGoogleLogin(selectedRole: _selectedRole);
    _isCompletingLogin = false;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (!result.success) return;
    Navigator.pushNamedAndRemoveUntil(context, result.route, (_) => false);
  }

  void _selectRole(UserRole role) {
    setState(() => _selectedRole = role);
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
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, color: AppColors.white),
              ),
              const SizedBox(height: 22),
              const Text(
                'Masuk ke UPI Connect+',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 8),
              Text(
                'Login menggunakan akun Google untuk mengakses fitur UPI Connect+.',
                style: AppTextStyles.body.copyWith(color: AppColors.textGray),
              ),
              const SizedBox(height: 24),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Role', style: AppTextStyles.subtitle),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserRole.values.map((role) {
                        final selected = role == _selectedRole;
                        return ChoiceChip(
                          label: Text(role.label),
                          selected: selected,
                          avatar: Icon(
                            _iconForRole(role),
                            size: 18,
                            color: selected
                                ? AppColors.white
                                : AppColors.primaryBlue,
                          ),
                          selectedColor: AppColors.primaryBlue,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.white
                                : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (_) => _selectRole(role),
                        );
                      }).toList(),
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

  IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.lecturer:
        return Icons.co_present_outlined;
    }
  }
}
