import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/user_model.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final student = state.student;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Profil', style: AppTextStyles.headline),
                ),
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: () async {
                    await state.signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (_) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProfileCard(
              student: student,
              isUploadingPhoto: _isUploadingPhoto,
              onEditProfile: () => _showEditProfileDialog(context, student),
              onPickPhoto: () => _pickAndUploadPhoto(context),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Skill',
              actionLabel: 'Edit',
              onAction: () => _showEditProfileDialog(context, student),
            ),
            const SizedBox(height: 10),
            if (student.skills.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Belum ada skill. Tekan Edit untuk melengkapi profil.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: student.skills
                    .map((skill) => SkillChip(label: skill))
                    .toList(),
              ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Riwayat Prestasi',
              actionLabel: 'Tambah',
              onAction: () => _showAddAchievementDialog(context),
            ),
            const SizedBox(height: 10),
            if (state.isAchievementsLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.achievementError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.achievementError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (state.achievements.isEmpty)
              CustomCard(
                child: Text(
                  'Belum ada prestasi. Tambahkan pengalaman lomba, peran, dan hasil yang pernah dicapai.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
              )
            else
              ...state.achievements.map(
                (achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AchievementCard(achievement: achievement),
                ),
              ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Tambah Prestasi',
              icon: Icons.add_rounded,
              onPressed: () => _showAddAchievementDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final appState = AppStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 84,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final message = await appState.uploadStudentProfilePhoto(
      bytes: bytes,
      fileName: picked.name,
      contentType: picked.mimeType ?? _contentTypeFromName(picked.name),
    );
    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showEditProfileDialog(BuildContext context, UserModel student) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student.name);
    final programController = TextEditingController(
      text: student.program ?? '',
    );
    final yearController = TextEditingController(
      text: student.year?.toString() ?? '',
    );
    final skillsController = TextEditingController(
      text: student.skills.join(', '),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: programController,
                  decoration: const InputDecoration(labelText: 'Program studi'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Angkatan'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: skillsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Skill',
                    hintText: 'Contoh: Flutter, UI/UX, Pitching',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final skills = skillsController.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList();
              final message = await AppStateScope.of(context)
                  .updateStudentProfile(
                    name: nameController.text.trim(),
                    studyProgram: programController.text.trim(),
                    batchYear: int.tryParse(yearController.text.trim()),
                    skills: skills,
                  );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddAchievementDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final competitionController = TextEditingController();
    final roleController = TextEditingController();
    final awardController = TextEditingController();
    final categoryController = TextEditingController();
    final levelController = TextEditingController();
    final yearController = TextEditingController(
      text: DateTime.now().year.toString(),
    );
    final certificateController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Prestasi'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: competitionController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama lomba',
                    hintText: 'Contoh: GEMASTIK',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama lomba wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Sebagai apa',
                    hintText: 'Contoh: Ketua Tim, UI/UX Designer',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Peran wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: awardController,
                  decoration: const InputDecoration(
                    labelText: 'Capaian',
                    hintText: 'Contoh: Juara 1, Finalis, Peserta',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Capaian wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori / bidang',
                    hintText: 'Contoh: Software Development',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: levelController,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat',
                    hintText: 'Contoh: Kampus, Regional, Nasional',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tahun'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: certificateController,
                  decoration: const InputDecoration(
                    labelText: 'Link sertifikat / bukti',
                    hintText: 'Opsional',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi kontribusi',
                    hintText: 'Ceritakan tugas atau kontribusi kamu',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final message = await AppStateScope.of(context)
                  .createAchievementApi(
                    competitionName: competitionController.text.trim(),
                    award: awardController.text.trim(),
                    roleInCompetition: roleController.text.trim(),
                    category: categoryController.text.trim(),
                    level: levelController.text.trim(),
                    year: yearController.text.trim().isEmpty
                        ? DateTime.now().year.toString()
                        : yearController.text.trim(),
                    certificateLink: certificateController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.student,
    required this.isUploadingPhoto,
    required this.onEditProfile,
    required this.onPickPhoto,
  });

  final UserModel student;
  final bool isUploadingPhoto;
  final VoidCallback onEditProfile;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final program = student.program?.trim();
    final year = student.year?.toString();
    final subtitle = [
      if (program != null && program.isNotEmpty) program,
      if (year != null && year.isNotEmpty) 'Angkatan $year',
    ].join(' - ');

    return CustomCard(
      color: AppColors.primaryBlue,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.white,
                backgroundImage:
                    student.avatarUrl != null && student.avatarUrl!.isNotEmpty
                    ? NetworkImage(student.avatarUrl!)
                    : null,
                child: student.avatarUrl == null || student.avatarUrl!.isEmpty
                    ? Text(
                        student.name.isEmpty
                            ? '?'
                            : student.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: isUploadingPhoto ? null : onPickPhoto,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.primaryBlue),
                    ),
                    child: isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.deepNavy,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name.isEmpty ? 'Lengkapi nama profil' : student.name,
                  style: AppTextStyles.title.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'Lengkapi prodi dan angkatan' : subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onEditProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.white.withAlpha(120)),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Profil'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.competitionName,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.award,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (achievement.roleInCompetition.isNotEmpty)
                      SkillChip(
                        label: achievement.roleInCompetition,
                        compact: true,
                      ),
                    if (achievement.category.isNotEmpty)
                      SkillChip(label: achievement.category, compact: true),
                    if (achievement.level.isNotEmpty)
                      SkillChip(label: achievement.level, compact: true),
                  ],
                ),
                if (achievement.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(achievement.description, style: AppTextStyles.muted),
                ],
                if (achievement.certificateLink.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    achievement.certificateLink,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            achievement.year,
            style: AppTextStyles.small.copyWith(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}
