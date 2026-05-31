import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _competitionController.dispose();
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
    );
    if (!mounted) return;
    setState(() => _isPublishing = false);
    _titleController.clear();
    _descriptionController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

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
            const SectionHeader(title: 'Postingan Lokal'),
            const SizedBox(height: 10),
            ...state.posts
                .take(3)
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.type,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(post.title, style: AppTextStyles.subtitle),
                          const SizedBox(height: 4),
                          Text(post.competition, style: AppTextStyles.muted),
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
