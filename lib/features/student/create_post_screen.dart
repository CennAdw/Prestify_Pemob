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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController(
    text: 'Flutter, UI/UX, Pitching',
  );
  final _competitionController = TextEditingController(text: 'GEMASTIK XVII');

  String _postType = 'Mencari Anggota';
  bool _isPublishing = false;

  final _postTypes = const ['Mencari Tim', 'Mencari Anggota'];
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _posterBytes;
  String? _posterFileName;
  String? _posterContentType;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _competitionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppStateScope.of(context);
    final competitionName = _competitionController.text.trim();
    setState(() => _isPublishing = true);
    final message = await state.publishRecruitmentPost(
      type: _postType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      skills: _skillsController.text.trim(),
      competition: competitionName,
      posterBytes: _posterBytes,
      posterFileName: _posterFileName,
      posterContentType: _posterContentType,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isPublishing = false);
    _titleController.clear();
    _descriptionController.clear();
    _notesController.clear();
    setState(() {
      _posterBytes = null;
      _posterFileName = null;
      _posterContentType = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final recentTeams = state.teams.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Postingan', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              'Publikasikan kebutuhan mencari tim atau mencari anggota.',
              style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: 18),
            CustomCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saya ingin', style: AppTextStyles.subtitle),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _postType,
                      items: _postTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _postType = value ?? _postType),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul postingan',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Judul wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        labelText: 'Skill yang dibutuhkan',
                        hintText: 'Contoh: Flutter, UI/UX, Pitching',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _competitionController,
                      decoration: const InputDecoration(
                        labelText: 'Pilihan lomba',
                        hintText: 'Contoh: GEMASTIK XVII',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nama lomba wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Catatan untuk perekrutan (opsional)',
                        hintText: 'Catatan terkait tim atau persyaratan khusus',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickPoster,
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Poster'),
                        ),
                        const SizedBox(width: 12),
                        if (_posterBytes != null)
                          const Text('Poster siap dipublikasikan'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _isPublishing ? 'Mengirim...' : 'Publikasikan',
                      icon: Icons.publish_rounded,
                      onPressed: _isPublishing ? null : _publish,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Tim Recruitment Terbaru'),
            const SizedBox(height: 10),
            if (state.isTeamsLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.teamError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.teamError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (recentTeams.isEmpty)
              CustomCard(
                child: Text(
                  'Belum ada tim dari Supabase.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
              )
            else
              ...recentTeams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.status,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(team.name, style: AppTextStyles.subtitle),
                        const SizedBox(height: 4),
                        Text(team.competitionName, style: AppTextStyles.muted),
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
}
