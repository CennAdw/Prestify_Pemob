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

  String _postType = 'Mencari Anggota';
  String _competition = 'GEMASTIK XVII';
  bool _isPublishing = false;

  final _postTypes = const [
    'Mencari Tim',
    'Mencari Anggota',
    'Mencari Dosen Pembimbing',
    'Mencari Informasi Lomba',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadCompetitions();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppStateScope.of(context);
    final competitionName =
        state.competitions.any((item) => item.name == _competition)
        ? _competition
        : state.competitions.first.name;
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
    final competitionOptions = state.competitions
        .map((item) => item.name)
        .toList();
    final dropdownCompetition = competitionOptions.contains(_competition)
        ? _competition
        : (competitionOptions.isNotEmpty
              ? competitionOptions.first
              : _competition);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Postingan', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              'Publikasikan kebutuhan tim, anggota, dosen pembimbing, atau info lomba.',
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
                    if (state.isCompetitionsLoading) ...[
                      const LinearProgressIndicator(
                        minHeight: 4,
                        color: AppColors.primaryBlue,
                        backgroundColor: AppColors.lightBlue,
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: dropdownCompetition,
                      decoration: const InputDecoration(
                        labelText: 'Pilihan lomba',
                      ),
                      items: competitionOptions
                          .map(
                            (competition) => DropdownMenuItem(
                              value: competition,
                              child: Text(competition),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _competition = value ?? _competition),
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
