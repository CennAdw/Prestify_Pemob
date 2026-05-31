import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/lecturer_model.dart';
import 'lecturer_detail_screen.dart';

class LecturerFinderScreen extends StatefulWidget {
  const LecturerFinderScreen({super.key});

  @override
  State<LecturerFinderScreen> createState() => _LecturerFinderScreenState();
}

class _LecturerFinderScreenState extends State<LecturerFinderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadLecturers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dosen Pembimbing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          ...state.lecturers.map(
            (lecturer) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _LecturerCard(lecturer: lecturer),
            ),
          ),
        ],
      ),
    );
  }
}

class _LecturerCard extends StatelessWidget {
  const _LecturerCard({required this.lecturer});

  final LecturerModel lecturer;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isActionEnabled = lecturer.isAvailable && !lecturer.hasRequested;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.lightBlue,
                child: Text(
                  lecturer.name.isEmpty
                      ? '?'
                      : lecturer.name.replaceFirst('Dr. ', '').characters.first,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lecturer.name, style: AppTextStyles.subtitle),
                    const SizedBox(height: 4),
                    Text(
                      'Kuota ${lecturer.currentQuota}/${lecturer.maxQuota}',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
              SkillChip(
                label: lecturer.status,
                backgroundColor: lecturer.isAvailable
                    ? AppColors.successGreen.withAlpha(28)
                    : AppColors.alertCoral.withAlpha(26),
                textColor: lecturer.isAvailable
                    ? AppColors.successGreen
                    : AppColors.alertCoral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lecturer.expertise
                .map((skill) => SkillChip(label: skill, compact: true))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Detail',
                  outlined: true,
                  icon: Icons.person_search_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LecturerDetailScreen(lecturerId: lecturer.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: lecturer.hasRequested
                      ? 'Request Terkirim'
                      : lecturer.isAvailable
                      ? 'Ajukan'
                      : 'Kuota Penuh',
                  icon: lecturer.hasRequested
                      ? Icons.check_circle_rounded
                      : Icons.send_rounded,
                  onPressed: isActionEnabled
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
    );
  }
}
