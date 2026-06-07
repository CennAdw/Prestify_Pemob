import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isUploadingDocument = false;

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
    final hasPortfolio =
        student.portfolioUrl != null && student.portfolioUrl!.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profil', style: AppTextStyles.headline),
                        Text(
                          'Kelola portofolio dan prestasi kamu',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
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
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  _ProfileCard(
                    student: student,
                    isUploadingPhoto: _isUploadingPhoto,
                    onEditProfile: () =>
                        _showEditProfileDialog(context, student),
                    onPickPhoto: () => _pickAndUploadPhoto(context),
                  ),
                  const SizedBox(height: 20),

                  // CV / Portfolio section
                  SectionHeader(
                    title: 'CV / Portofolio',
                    actionLabel: 'Unggah',
                    onAction: () => _pickAndUploadDocument(context),
                  ),
                  const SizedBox(height: 10),
                  if (!hasPortfolio)
                    _EmptyPortfolioBanner(
                      isUploading: _isUploadingDocument,
                      onUpload: () => _pickAndUploadDocument(context),
                    )
                  else
                    _PortfolioCard(
                      url: student.portfolioUrl!,
                      isUploading: _isUploadingDocument,
                      onReplace: () => _pickAndUploadDocument(context),
                      onDownload: () => _downloadPortfolio(student.portfolioUrl!),
                    ),

                  const SizedBox(height: 20),

                  // Skills
                  SectionHeader(
                    title: 'Skill',
                    actionLabel: 'Edit',
                    onAction: () => _showEditProfileDialog(context, student),
                  ),
                  const SizedBox(height: 10),
                  if (student.skills.isEmpty)
                    _EmptyCard(
                      message:
                          'Belum ada skill. Tekan Edit untuk melengkapi profil.',
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: student.skills
                          .map((skill) => SkillChip(label: skill))
                          .toList(),
                    ),

                  const SizedBox(height: 24),

                  // Achievements
                  SectionHeader(
                    title: 'Riwayat Prestasi',
                    actionLabel: 'Tambah',
                    onAction: () => _showAddAchievementDialog(context),
                  ),
                  const SizedBox(height: 10),
                  if (state.isAchievementsLoading) ...[
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.borderLight,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.achievementError != null) ...[
                    _ErrorBanner(message: state.achievementError!),
                    const SizedBox(height: 12),
                  ],
                  if (state.achievements.isEmpty)
                    _EmptyCard(
                      message:
                          'Belum ada prestasi. Tambahkan pengalaman lomba, peran, dan hasil yang pernah dicapai.',
                    )
                  else
                    ...state.achievements.map(
                      (achievement) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AchievementCard(achievement: achievement),
                      ),
                    ),

                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Tambah Prestasi',
                    icon: Icons.add_rounded,
                    outlined: true,
                    onPressed: () => _showAddAchievementDialog(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPortfolio(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka file: $e')),
      );
    }
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
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickAndUploadDocument(BuildContext context) async {
    final appState = AppStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    if (file.bytes == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal membaca file.')),
      );
      return;
    }

    setState(() => _isUploadingDocument = true);
    final message = await appState.uploadStudentPortfolioDocument(
      bytes: file.bytes!,
      fileName: file.name,
      contentType: 'application/pdf',
    );
    if (!mounted) return;
    setState(() => _isUploadingDocument = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showEditProfileDialog(
      BuildContext context, UserModel student) async {
    final nameController = TextEditingController(text: student.name);
    final facultyController =
        TextEditingController(text: student.faculty ?? '');
    final programController =
        TextEditingController(text: student.program ?? '');
    final yearController =
        TextEditingController(text: student.year?.toString() ?? '');
    final skillsController =
        TextEditingController(text: student.skills.join(', '));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profil'),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameController, 'Nama lengkap'),
              const SizedBox(height: 10),
              _dialogField(facultyController, 'Fakultas'),
              const SizedBox(height: 10),
              _dialogField(programController, 'Program studi'),
              const SizedBox(height: 10),
              _dialogField(yearController, 'Angkatan',
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _dialogField(
                skillsController,
                'Skill (pisahkan koma)',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final appState = AppStateScope.of(context);
              final skills = skillsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final message = await appState.updateStudentProfile(
                name: nameController.text,
                faculty: facultyController.text,
                studyProgram: programController.text,
                batchYear: int.tryParse(yearController.text.trim()),
                skills: skills,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAchievementDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final awardController = TextEditingController();
    final roleController = TextEditingController();
    final categoryController = TextEditingController();
    final levelController = TextEditingController();
    final yearController = TextEditingController();
    final certController = TextEditingController();
    final descController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Prestasi'),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameController, 'Nama lomba'),
              const SizedBox(height: 10),
              _dialogField(awardController, 'Penghargaan (mis. Juara 1)'),
              const SizedBox(height: 10),
              _dialogField(roleController, 'Peran dalam kompetisi'),
              const SizedBox(height: 10),
              _dialogField(categoryController, 'Kategori'),
              const SizedBox(height: 10),
              _dialogField(levelController, 'Tingkat (Nasional/Internasional)'),
              const SizedBox(height: 10),
              _dialogField(yearController, 'Tahun',
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _dialogField(certController, 'Link sertifikat (opsional)'),
              const SizedBox(height: 10),
              _dialogField(descController, 'Deskripsi (opsional)',
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final appState = AppStateScope.of(context);
              final message = await appState.createAchievementApi(
                competitionName: nameController.text,
                award: awardController.text,
                roleInCompetition: roleController.text,
                category: categoryController.text,
                level: levelController.text,
                year: yearController.text.trim().isEmpty
                    ? DateTime.now().year.toString()
                    : yearController.text.trim(),
                certificateLink: certController.text.trim(),
                description: descController.text.trim(),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  TextField _dialogField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      );
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertCoralLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertCoral.withAlpha(60)),
      ),
      child: Text(
        message,
        style: AppTextStyles.small.copyWith(color: AppColors.alertCoral),
      ),
    );
  }
}

class _EmptyPortfolioBanner extends StatelessWidget {
  const _EmptyPortfolioBanner({
    required this.isUploading,
    required this.onUpload,
  });
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: AppColors.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada CV / Portofolio',
            style: AppTextStyles.subtitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Unggah file PDF untuk memperkuat profil kamu.',
            style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: isUploading ? 'Mengunggah...' : 'Unggah PDF',
            icon: Icons.upload_file_rounded,
            onPressed: isUploading ? null : onUpload,
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.url,
    required this.isUploading,
    required this.onReplace,
    required this.onDownload,
  });

  final String url;
  final bool isUploading;
  final VoidCallback onReplace;
  final VoidCallback onDownload;

  String get _fileName {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return 'portfolio.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CV / Portofolio', style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(
                      _fileName,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreenLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Terunggah',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Download CV',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : onReplace,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textGray,
                    side: const BorderSide(color: AppColors.borderMedium),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    isUploading
                        ? Icons.hourglass_top_rounded
                        : Icons.upload_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isUploading ? 'Mengunggah...' : 'Ganti File',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
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
      if (student.nim != null && student.nim!.isNotEmpty) 'NIM ${student.nim}',
      if (student.faculty != null && student.faculty!.isNotEmpty)
        student.faculty!,
    ].join(' · ');
    final sub2 = [
      if (program != null && program.isNotEmpty) program,
      if (year != null && year.isNotEmpty) 'Angkatan $year',
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientMid],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.white.withAlpha(40),
                    backgroundImage: student.avatarUrl != null &&
                            student.avatarUrl!.isNotEmpty
                        ? NetworkImage(student.avatarUrl!)
                        : null,
                    child: student.avatarUrl == null ||
                            student.avatarUrl!.isEmpty
                        ? Text(
                            student.name.isEmpty
                                ? '?'
                                : student.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: isUploadingPhoto ? null : onPickPhoto,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 2,
                          ),
                        ),
                        child: isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.deepNavy,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: AppColors.deepNavy,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name.isEmpty
                          ? 'Lengkapi nama profil'
                          : student.name,
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.white.withAlpha(200),
                        ),
                      ),
                    ],
                    if (sub2.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub2,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.white.withAlpha(170),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: BorderSide(color: AppColors.white.withAlpha(100)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Edit Profil',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentYellow, Color(0xFFEF9F27)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.competitionName,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    achievement.award,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
                  const SizedBox(height: 6),
                  Text(achievement.description, style: AppTextStyles.muted),
                ],
                if (achievement.certificateLink.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 13,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          achievement.certificateLink,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              achievement.year,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}