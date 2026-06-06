import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  // Mencari Anggota fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController(text: 'Flutter, UI/UX, Pitching');
  final _competitionController = TextEditingController(text: 'GEMASTIK XVII');
  final _notesController = TextEditingController();

  // Mencari Tim fields
  final _cariTimTitleController = TextEditingController();
  final _cariTimDescController = TextEditingController();
  final _cariTimSkillsController = TextEditingController(text: 'Flutter, UI/UX');
  final _cariTimCompetitionController = TextEditingController(text: 'GEMASTIK XVII');
  final _cariTimNotesController = TextEditingController();

  String _postType = 'Mencari Anggota';
  int _maxMembers = 5;
  bool _isPublishing = false;

  final _postTypes = const ['Mencari Anggota', 'Mencari Tim'];
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _posterBytes;
  String? _posterFileName;
  String? _posterContentType;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _competitionController.dispose();
    _notesController.dispose();
    _cariTimTitleController.dispose();
    _cariTimDescController.dispose();
    _cariTimSkillsController.dispose();
    _cariTimCompetitionController.dispose();
    _cariTimNotesController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppStateScope.of(context);
    setState(() => _isPublishing = true);

    String message;
    if (_postType == 'Mencari Anggota') {
      message = await state.publishRecruitmentPost(
        type: _postType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _skillsController.text.trim(),
        competition: _competitionController.text.trim(),
        maxMembers: _maxMembers,
        posterBytes: _posterBytes,
        posterFileName: _posterFileName,
        posterContentType: _posterContentType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _posterBytes = null;
          _posterFileName = null;
          _posterContentType = null;
        });
        _titleController.clear();
        _descriptionController.clear();
        _notesController.clear();
      }
    } else {
      message = await state.publishAnggotaPost(
        title: _cariTimTitleController.text.trim(),
        description: _cariTimDescController.text.trim(),
        skills: _cariTimSkillsController.text.trim(),
        competition: _cariTimCompetitionController.text.trim(),
        notes: _cariTimNotesController.text.trim().isEmpty
            ? null
            : _cariTimNotesController.text.trim(),
      );
      if (mounted) {
        _cariTimTitleController.clear();
        _cariTimDescController.clear();
        _cariTimNotesController.clear();
      }
    }

    if (!mounted) return;
    setState(() => _isPublishing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPoster() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 84,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _posterBytes = bytes;
      _posterFileName = picked.name;
      _posterContentType = picked.mimeType ?? 'image/jpeg';
    });
  }

  InputDecoration _inputDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: AppColors.backgroundSoftGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.alertCoral),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final recentTeams = state.teams.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buat Postingan', style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(
              'Publikasikan kebutuhan mencari tim atau anggota.',
              style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: 24),

            // Post type selector
            Row(
              children: _postTypes.map((type) {
                final selected = _postType == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type == _postTypes.first ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _postType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type == 'Mencari Tim'
                                  ? Icons.person_search_rounded
                                  : Icons.group_add_rounded,
                              color: selected ? AppColors.white : AppColors.textGray,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type,
                              style: AppTextStyles.small.copyWith(
                                color: selected ? AppColors.white : AppColors.textBody,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Form
            Form(
              key: _formKey,
              child: _postType == 'Mencari Anggota'
                  ? _buildCariAnggotaForm()
                  : _buildCariTimForm(),
            ),

            const SizedBox(height: 28),
            const SectionHeader(title: 'Tim Recruitment Terbaru'),
            const SizedBox(height: 12),

            if (state.isTeamsLoading) ...[
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.borderLight,
              ),
              const SizedBox(height: 12),
            ],
            if (recentTeams.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  'Belum ada tim terbaru.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
              )
            else
              ...recentTeams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team.name, style: AppTextStyles.subtitle),
                              const SizedBox(height: 2),
                              Text(team.competitionName, style: AppTextStyles.muted),
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
                            team.status,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w700,
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
    );
  }

  // ── Form: Mencari Anggota ─────────────────────────────────────────────────
  Widget _buildCariAnggotaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(
            'Nama tim',
            hint: 'Contoh: Tim Prestify',
            prefix: const Icon(Icons.title_rounded, color: AppColors.primaryBlue),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nama tim wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 6,
          decoration: _inputDecoration(
            'Deskripsi tim & kebutuhan',
            hint: 'Ceritakan tentang tim dan posisi yang dibutuhkan.',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _skillsController,
          decoration: _inputDecoration(
            'Skill yang dibutuhkan',
            hint: 'Flutter, UI/UX, Pitching',
            prefix: const Icon(Icons.auto_awesome_outlined, color: AppColors.primaryBlue),
          ),
        ),
        const SizedBox(height: 14),

        // Slider max anggota
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group_rounded, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Maksimal Anggota',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '$_maxMembers orang',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('2', style: AppTextStyles.muted),
                Expanded(
                  child: Slider(
                    value: _maxMembers.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    activeColor: AppColors.primaryBlue,
                    inactiveColor: AppColors.lightBlue,
                    onChanged: (v) => setState(() => _maxMembers = v.round()),
                  ),
                ),
                const Text('10', style: AppTextStyles.muted),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),
        TextFormField(
          controller: _competitionController,
          decoration: _inputDecoration(
            'Nama lomba',
            hint: 'Contoh: GEMASTIK XVII',
            prefix: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryBlue),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nama lomba wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _notesController,
          minLines: 2,
          maxLines: 4,
          decoration: _inputDecoration(
            'Catatan untuk perekrutan (opsional)',
            hint: 'Persyaratan khusus, kontak, dll.',
          ),
        ),
        const SizedBox(height: 16),

        // Poster picker
        GestureDetector(
          onTap: _pickPoster,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _posterBytes != null
                  ? AppColors.successGreenLight
                  : AppColors.backgroundMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _posterBytes != null
                    ? AppColors.successGreen.withAlpha(80)
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _posterBytes != null
                        ? AppColors.successGreen.withAlpha(30)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _posterBytes != null
                        ? Icons.check_circle_outline_rounded
                        : Icons.image_outlined,
                    color: _posterBytes != null
                        ? AppColors.successGreen
                        : AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _posterBytes != null ? 'Poster siap' : 'Unggah Poster Lomba',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                      ),
                      Text(
                        _posterBytes != null
                            ? _posterFileName ?? ''
                            : 'Tap untuk pilih gambar (opsional)',
                        style: AppTextStyles.small.copyWith(color: AppColors.textGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_posterBytes != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textGray),
                    onPressed: () => setState(() {
                      _posterBytes = null;
                      _posterFileName = null;
                      _posterContentType = null;
                    }),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        PrimaryButton(
          label: _isPublishing ? 'Mengirim...' : 'Publikasikan',
          icon: Icons.publish_rounded,
          onPressed: _isPublishing ? null : _publish,
        ),
      ],
    );
  }

  // ── Form: Mencari Tim ─────────────────────────────────────────────────────
  Widget _buildCariTimForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _cariTimTitleController,
          decoration: _inputDecoration(
            'Judul postingan',
            hint: 'Contoh: Mencari tim untuk GEMASTIK XVII',
            prefix: const Icon(Icons.title_rounded, color: AppColors.primaryBlue),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cariTimDescController,
          minLines: 4,
          maxLines: 6,
          decoration: _inputDecoration(
            'Perkenalan diri & motivasi',
            hint: 'Ceritakan tentang dirimu, pengalamanmu, dan kenapa kamu cocok bergabung.',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cariTimSkillsController,
          decoration: _inputDecoration(
            'Skill yang kamu miliki',
            hint: 'Flutter, UI/UX, Machine Learning',
            prefix: const Icon(Icons.auto_awesome_outlined, color: AppColors.primaryBlue),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cariTimCompetitionController,
          decoration: _inputDecoration(
            'Lomba yang diminati',
            hint: 'Contoh: GEMASTIK XVII, PKM, dll.',
            prefix: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryBlue),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nama lomba wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cariTimNotesController,
          minLines: 2,
          maxLines: 4,
          decoration: _inputDecoration(
            'Catatan tambahan (opsional)',
            hint: 'Ketersediaan waktu, preferensi tim, kontak, dll.',
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _isPublishing ? 'Mengirim...' : 'Publikasikan',
          icon: Icons.publish_rounded,
          onPressed: _isPublishing ? null : _publish,
        ),
      ],
    );
  }
}