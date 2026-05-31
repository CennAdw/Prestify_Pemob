import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';

class LecturerDetailScreen extends StatefulWidget {
  const LecturerDetailScreen({required this.lecturerId, super.key});

  final String lecturerId;

  @override
  State<LecturerDetailScreen> createState() => _LecturerDetailScreenState();
}

class _LecturerDetailScreenState extends State<LecturerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppStateScope.of(context).loadLecturerDetail(widget.lecturerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final lecturer = state.lecturerById(widget.lecturerId);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Dosen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isLecturersLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.lecturerError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.lecturerError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            CustomCard(
              color: AppColors.primaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    child: Text(
                      lecturer.name.isEmpty
                          ? '?'
                          : lecturer.name
                                .replaceFirst('Dr. ', '')
                                .characters
                                .first,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lecturer.name,
                    style: AppTextStyles.title.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lecturer.faculty,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.lightBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SkillChip(
                    label:
                        '${lecturer.status} - Kuota ${lecturer.currentQuota}/${lecturer.maxQuota}',
                    backgroundColor: AppColors.white.withAlpha(34),
                    textColor: AppColors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Bidang Keahlian'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lecturer.expertise
                  .map((skill) => SkillChip(label: skill))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Pengalaman Membimbing'),
            const SizedBox(height: 10),
            ...lecturer.experiences.map(
              (experience) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow.withAlpha(54),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.deepNavy,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(experience, style: AppTextStyles.body),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Konsultasi',
                    outlined: true,
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur konsultasi siap disambungkan ke jadwal dosen.',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: lecturer.hasRequested
                        ? 'Request Terkirim'
                        : 'Ajukan Pembimbing',
                    icon: lecturer.hasRequested
                        ? Icons.check_circle_rounded
                        : Icons.send_rounded,
                    onPressed: lecturer.isAvailable && !lecturer.hasRequested
                        ? () async {
                            final message = await state.requestLecturerApi(
                              lecturer.id,
                            );
                            if (!context.mounted) return;
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Berhasil'),
                                content: Text(message),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Oke'),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
