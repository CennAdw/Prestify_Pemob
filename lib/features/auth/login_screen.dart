import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_state.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  bool _isCompletingLogin = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.isReady) {
      _authSubscription = SupabaseService.authStateChanges.listen((state) {
        if (state.session != null && state.event != AuthChangeEvent.signedOut) {
          _completeAuthenticatedLogin();
        }
      });
      if (SupabaseService.client.auth.currentSession != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _completeAuthenticatedLogin();
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithNim() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isCompletingLogin) return;
    _isCompletingLogin = true;
    final result = await AppStateScope.of(context).signInWithNim(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );
    _isCompletingLogin = false;
    if (!mounted) return;
    _handleResult(result);
  }

  Future<void> _signInWithGoogle() async {
    final result = await AppStateScope.of(context).signInWithGoogle();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _completeAuthenticatedLogin() async {
    if (_isCompletingLogin) return;
    _isCompletingLogin = true;
    final result = await AppStateScope.of(context).completeAuthenticatedLogin();
    _isCompletingLogin = false;
    if (!mounted) return;
    _handleResult(result);
  }

  void _handleResult(LoginResult result) {
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
      backgroundColor: AppColors.backgroundSoftGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & brand
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'images/prestify_white.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Prestify',
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text('Selamat datang\nkembali 👋', style: AppTextStyles.display),
                const SizedBox(height: 8),
                Text(
                  'Masuk dengan NIM/NIDN dan password, atau akun Google @upi.edu.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
                const SizedBox(height: 32),

                // Form card
                CustomCard(
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: 'NIM / NIDN',
                          hintText: 'Masukkan NIM atau NIDN',
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundSoftGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'NIM atau NIDN wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primaryBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundSoftGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _passwordVisible
                                ? 'Sembunyikan'
                                : 'Tampilkan',
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: state.isAuthLoading ? 'Masuk...' : 'Masuk',
                        icon: Icons.login_rounded,
                        onPressed: state.isAuthLoading ? null : _signInWithNim,
                      ),
                      const SizedBox(height: 16),
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.borderLight,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'atau',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.borderLight,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: state.isAuthLoading
                            ? 'Menghubungkan...'
                            : 'Lanjutkan dengan Google',
                        outlined: true,
                        icon: Icons.account_circle_outlined,
                        onPressed: state.isAuthLoading
                            ? null
                            : _signInWithGoogle,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Register link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun?',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                      TextButton(
                        onPressed: state.isAuthLoading
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegistrationScreen(),
                                ),
                              ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: const Text(
                          'Daftar sekarang',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderFocus),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hanya email @upi.edu yang dapat digunakan. Role dosen ditentukan otomatis dari daftar dosen terverifikasi.',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}