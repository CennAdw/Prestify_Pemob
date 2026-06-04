import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/auth_config.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    this.initialEmail = '',
    this.emailLocked = false,
    super.key,
  });

  final String initialEmail;
  final bool emailLocked;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppStateScope.of(context);
    final result = await state.verifyEmailCode(
      email: _emailController.text,
      code: _codeController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (!result.success) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _resend() async {
    final email = _emailController.text.trim();
    if (!isAllowedUpiEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email @upi.edu yang valid.')),
      );
      return;
    }
    final result = await AppStateScope.of(context).sendVerificationCode(email);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periksa email UPI kamu',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan kode 6 digit yang dikirim melalui Resend. Kode berlaku selama 10 menit.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
                const SizedBox(height: 20),
                CustomCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        readOnly: widget.emailLocked,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email UPI',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (value) => isAllowedUpiEmail(value ?? '')
                            ? null
                            : 'Email wajib menggunakan domain @upi.edu',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Kode verifikasi',
                          prefixIcon: Icon(Icons.password_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          final code = value?.trim() ?? '';
                          if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
                            return 'Masukkan kode 6 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: state.isAuthLoading
                            ? 'Memverifikasi...'
                            : 'Verifikasi Email',
                        icon: Icons.verified_rounded,
                        onPressed: state.isAuthLoading ? null : _verify,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: state.isAuthLoading ? null : _resend,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Kirim ulang kode'),
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
