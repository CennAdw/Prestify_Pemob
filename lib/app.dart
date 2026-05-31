import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'data/app_state.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/lecturer/lecturer_dashboard_screen.dart';
import 'features/student/student_shell.dart';

class UpiConnectApp extends StatefulWidget {
  const UpiConnectApp({super.key});

  @override
  State<UpiConnectApp> createState() => _UpiConnectAppState();
}

class _UpiConnectAppState extends State<UpiConnectApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        title: 'UPI Connect+',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/student': (_) => const StudentShell(),
          '/lecturer': (_) => const LecturerDashboardScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.secondaryBlue,
      surface: AppColors.white,
      error: AppColors.alertCoral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundSoftGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.4,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.lightBlue,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryBlue
                : AppColors.textGray,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    required AppState notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
