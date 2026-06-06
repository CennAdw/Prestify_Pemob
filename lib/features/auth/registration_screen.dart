import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/auth_config.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/user_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _facultyController = TextEditingController();
  final _programController = TextEditingController();
  final _yearController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _didPrefill = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool get _hasAuthenticatedAccount =>
      SupabaseService.isReady &&
      SupabaseService.client.auth.currentUser != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) return;
    _didPrefill = true;

    final state = AppStateScope.of(context);
    final profile = state.currentUser;
    final authUser = SupabaseService.isReady
        ? SupabaseService.client.auth.currentUser
        : null;
    _emailController.text = profile?.email ?? authUser?.email ?? '';
    _nameController.text =
        profile?.name ??
        authUser?.userMetadata?['full_name']?.toString() ??
        authUser?.userMetadata?['name']?.toString() ??
        '';
    _identifierController.text = profile?.nim ?? '';
    _facultyController.text = profile?.faculty ?? '';
    _programController.text = profile?.program ?? '';
    _yearController.text = profile?.year?.toString() ?? '';
    _skillsController.text = profile?.skills.join(', ') ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _identifierController.dispose();
    _facultyController.dispose();
    _programController.dispose();
    _yearController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final skills = _skillsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final state = AppStateScope.of(context);
    final result = _hasAuthenticatedAccount
        ? await state.completeCurrentRegistration(
            name: _nameController.text,
            academicIdentifier: _identifierController.text,
            faculty: _facultyController.text,
            studyProgram: _programController.text,
            batchYear: int.tryParse(_yearController.text.trim()),
            skills: skills,
          )
        : await state.registerWithPassword(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            academicIdentifier: _identifierController.text,
            faculty: _facultyController.text,
            studyProgram: _programController.text,
            batchYear: int.tryParse(_yearController.text.trim()),
            skills: skills,
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
    final role = state.currentUser?.role;
    final isLecturer = role == UserRole.lecturer;
    final identifierLabel = isLecturer
        ? 'NIDN'
        : role == UserRole.student
        ? 'NIM'
        : 'NIM / NIDN';

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Prestify')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasAuthenticatedAccount
                      ? 'Lengkapi profil akun'
                      : 'Buat akun baru',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 8),
                Text(
                  _hasAuthenticatedAccount
                      ? 'Akun Google kamu sudah terhubung. Lengkapi data akademik untuk masuk ke Prestify.'
                      : 'Gunakan email resmi @upi.edu. Kamu harus memverifikasi email sebelum dapat login.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
                const SizedBox(height: 20),
                if (_hasAuthenticatedAccount) ...[
                  CustomCard(
                    color: AppColors.lightBlue,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Akun Google terhubung',
                                style: AppTextStyles.subtitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _emailController.text,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                CustomCard(
                  child: Column(
                    children: [
                      if (!_hasAuthenticatedAccount) ...[
                        TextFormField(
                          controller: _emailController,
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          autofillHints: const [AutofillHints.newPassword],
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
                          validator: (value) => (value?.length ?? 0) >= 8
                              ? null
                              : 'Password minimal 8 karakter',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              tooltip: _confirmPasswordVisible
                                  ? 'Sembunyikan password'
                                  : 'Tampilkan password',
                              onPressed: () => setState(
                                () => _confirmPasswordVisible =
                                    !_confirmPasswordVisible,
                              ),
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == _passwordController.text
                              ? null
                              : 'Konfirmasi password tidak sama',
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: _requiredValidator('Nama'),
                      ),
                      const SizedBox(height: 12),
                      if (isLecturer)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NIDN diambil otomatis dari daftar dosen terverifikasi.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: identifierLabel,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: _requiredValidator(identifierLabel),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _facultyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Fakultas',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        validator: _requiredValidator('Fakultas'),
                      ),
                      if (!isLecturer) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _programController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Program studi',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          validator: _requiredValidator('Program studi'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Angkatan',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                            final year = int.tryParse(value?.trim() ?? '');
                            if (year == null || year < 2000 || year > 2100) {
                              return 'Masukkan tahun angkatan yang valid';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _skillsController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: isLecturer
                              ? 'Bidang keahlian'
                              : 'Skill yang dimiliki',
                          hintText: 'Pisahkan dengan koma',
                          prefixIcon: const Icon(Icons.auto_awesome_outlined),
                        ),
                        validator: _requiredValidator(
                          isLecturer ? 'Bidang keahlian' : 'Skill',
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: state.isAuthLoading
                            ? 'Memproses...'
                            : _hasAuthenticatedAccount
                            ? 'Simpan dan Lanjutkan'
                            : 'Daftar Sekarang',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: state.isAuthLoading ? null : _submit,
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

  FormFieldValidator<String> _requiredValidator(String label) {
    return (value) =>
        value == null || value.trim().isEmpty ? '$label wajib diisi' : null;
  }
}
