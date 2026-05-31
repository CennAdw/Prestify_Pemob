import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: _emailForRole(_selectedRole),
    );
    _passwordController = TextEditingController(text: '123456');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _emailForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'candra@upi.edu';
      case UserRole.lecturer:
        return 'dosen@upi.edu';
    }
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _emailController.text = _emailForRole(role);
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final state = AppStateScope.of(context);
    final result = await state.login(
      selectedRole: _selectedRole,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
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
                'Gunakan akun dummy sesuai role untuk memulai demo.',
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
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email / NIM',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: state.isAuthLoading ? 'Menghubungkan...' : 'Login',
                      icon: Icons.login_rounded,
                      onPressed: state.isAuthLoading ? null : _login,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              CustomCard(
                color: AppColors.lightBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Akun Dummy', style: AppTextStyles.subtitle),
                    SizedBox(height: 10),
                    _DummyAccountLine(
                      label: 'Mahasiswa',
                      email: 'candra@upi.edu',
                    ),
                    _DummyAccountLine(label: 'Dosen', email: 'dosen@upi.edu'),
                  ],
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

class _DummyAccountLine extends StatelessWidget {
  const _DummyAccountLine({required this.label, required this.email});

  final String label;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(color: AppColors.primaryBlue),
            ),
          ),
          Expanded(
            child: Text(
              email,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
