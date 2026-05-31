import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import 'create_post_screen.dart';
import 'portfolio_screen.dart';
import 'student_home_screen.dart';
import 'team_finder_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppStateScope.of(context).loadStudentDashboard();
      }
    });
  }

  void _setTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeScreen(onNavigate: _setTab),
      const TeamFinderScreen(),
      const CreatePostScreen(),
      const _StudentNotificationScreen(),
      const PortfolioScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _setTab,
      ),
    );
  }
}

class _StudentNotificationScreen extends StatelessWidget {
  const _StudentNotificationScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Notifikasi', style: AppTextStyles.headline),
                ),
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request terkirim', style: AppTextStyles.subtitle),
                  const SizedBox(height: 6),
                  Text(
                    'Ketua tim Nawasena Tech akan menerima request bergabung kamu.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline GEMASTIK mendekat',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Lengkapi profil portofolio sebelum daftar.',
                          style: AppTextStyles.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Kembali ke Beranda',
              icon: Icons.home_rounded,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/student',
                (_) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
