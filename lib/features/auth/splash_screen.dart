import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/primary_button.dart';
import 'verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isCheckingSession = false;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.isReady) {
      _authSubscription = SupabaseService.authStateChanges.listen((state) {
        if (state.session != null && state.event != AuthChangeEvent.signedOut) {
          _startSessionRestore();
        }
      });
      if (SupabaseService.client.auth.currentSession != null) {
        _startSessionRestore();
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _startSessionRestore() {
    if (_isCheckingSession) return;
    _isCheckingSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    if (!SupabaseService.isReady ||
        SupabaseService.client.auth.currentSession == null) {
      if (mounted) setState(() => _isCheckingSession = false);
      return;
    }

    final result = await AppStateScope.of(context).completeAuthenticatedLogin();
    if (!mounted) return;
    if (result.code == 'EMAIL_NOT_VERIFIED') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            initialEmail: result.email ?? '',
            emailLocked: result.email?.isNotEmpty ?? false,
          ),
        ),
      );
      return;
    }
    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(context, result.route, (_) => false);
      return;
    }

    setState(() => _isCheckingSession = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepNavy,
              AppColors.primaryBlue,
              AppColors.secondaryBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white.withAlpha(60)),
                  ),
                  child: Image.asset(
                    'assets/images/prestify_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Prestify',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Prestasi Mahasiswa dalam Satu Platform',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Temukan Tim, Bangun Prestasi.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: _isCheckingSession ? 'Memeriksa akun...' : 'Mulai',
                  icon: _isCheckingSession
                      ? Icons.hourglass_top_rounded
                      : Icons.arrow_forward_rounded,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryBlue,
                  onPressed: _isCheckingSession
                      ? null
                      : () => Navigator.pushReplacementNamed(context, '/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
