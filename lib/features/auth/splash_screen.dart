import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isCheckingSession = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();

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
    _animController.dispose();
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
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid,
              AppColors.gradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withAlpha(12),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withAlpha(8),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(flex: 2),
                        // Logo
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.deepNavy.withAlpha(40),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'images/prestify_blue.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // App name
                        Text(
                          'Prestify',
                          style: AppTextStyles.display.copyWith(
                            color: AppColors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Prestasi Mahasiswa\ndalam Satu Platform',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.white.withAlpha(200),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        // Tagline chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.white.withAlpha(40),
                            ),
                          ),
                          child: Text(
                            '✦  Temukan Tim. Bangun Prestasi.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // CTA button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCheckingSession
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                    context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: AppTextStyles.buttonLabel.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isCheckingSession)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primaryBlue,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  _isCheckingSession
                                      ? 'Memeriksa akun...'
                                      : 'Mulai',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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