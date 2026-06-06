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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
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
                  'Gunakan NIM atau NIDN dan password, atau lanjutkan dengan akun Google @upi.edu.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
                const SizedBox(height: 24),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'NIM / NIDN',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'NIM atau NIDN wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _passwordVisible
                                ? 'Sembunyikan password'
                                : 'Tampilkan password',
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: state.isAuthLoading ? 'Masuk...' : 'Masuk',
                        icon: Icons.login_rounded,
                        onPressed: state.isAuthLoading ? null : _signInWithNim,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau', style: AppTextStyles.muted),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: state.isAuthLoading
                            ? 'Menghubungkan...'
                            : 'Login menggunakan Google',
                        outlined: true,
                        icon: Icons.account_circle_outlined,
                        onPressed: state.isAuthLoading
                            ? null
                            : _signInWithGoogle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun?', style: AppTextStyles.body),
                    TextButton(
                      onPressed: state.isAuthLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistrationScreen(),
                              ),
                            ),
                      child: const Text('Daftar sekarang'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomCard(
                  color: AppColors.lightBlue,
                  child: Text(
                    'Hanya email @upi.edu yang dapat digunakan. Role dosen ditentukan otomatis dari daftar dosen terverifikasi.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryBlue,
                    ),
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
