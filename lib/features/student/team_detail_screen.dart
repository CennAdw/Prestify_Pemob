import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final String teamId;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppStateScope.of(context).loadTeamDetail(widget.teamId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final team = state.teamById(widget.teamId);
    final studentSkills = state.student.skills
        .map((skill) => skill.toLowerCase())
        .toSet();
    final matchedSkills = team.requiredSkills
        .where((skill) => studentSkills.contains(skill.toLowerCase()))
        .toList();
    final missingSkills = team.requiredSkills
        .where((skill) => !studentSkills.contains(skill.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              color: AppColors.primaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillChip(
                    label: team.status,
                    backgroundColor: AppColors.white.withAlpha(34),
                    textColor: AppColors.white,
                    compact: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    team.name,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.competitionName,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.lightBlue,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deskripsi Tim',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          team.description,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Matching Score',
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                            Text(
                              '${team.matchingScore}%',
                              style: AppTextStyles.title.copyWith(
                                color: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: team.matchingScore / 100,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(99),
                          backgroundColor: AppColors.lightBlue,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Alasan Kecocokan',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 10),
                        if (team.requiredSkills.isEmpty)
                          Text(
                            'Tim belum mengisi kebutuhan skill.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textGray,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...matchedSkills.map(
                                (skill) => SkillChip(
                                  label: skill,
                                  icon: Icons.check_circle_rounded,
                                  backgroundColor: const Color(0xFFEAF8EE),
                                  textColor: AppColors.successGreen,
                                ),
                              ),
                              ...missingSkills.map(
                                (skill) => SkillChip(
                                  label: skill,
                                  icon: Icons.info_rounded,
                                  backgroundColor: const Color(0xFFFFF5F3),
                                  textColor: AppColors.alertCoral,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Anggota Tim'),
                  const SizedBox(height: 10),
                  ...team.members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.lightBlue,
                              child: Text(
                                member.name.isEmpty
                                    ? '?'
                                    : member.name.characters.first,
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
                                  Text(
                                    member.name,
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(member.role, style: AppTextStyles.muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SectionHeader(title: 'Skill yang Dibutuhkan'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: team.requiredSkills
                        .map((skill) => SkillChip(label: skill))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: team.hasRequested
                        ? 'Menunggu Persetujuan'
                        : 'Ajukan Bergabung',
                    icon: team.hasRequested
                        ? Icons.hourglass_top_rounded
                        : Icons.send_rounded,
                    onPressed: team.hasRequested
                        ? null
                        : () async {
                            final message = await state.requestJoinTeamApi(
                              team.id,
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
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
