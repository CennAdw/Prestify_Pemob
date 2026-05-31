import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/widgets/app_bottom_nav.dart';
import 'application_history_screen.dart';
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
      const ApplicationHistoryScreen(),
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
