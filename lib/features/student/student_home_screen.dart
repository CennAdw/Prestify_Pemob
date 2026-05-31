import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import 'lecturer_finder_screen.dart';
import 'team_detail_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({required this.onNavigate, super.key});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final student = state.student;
    final recommendedTeams = state.teams.take(2).toList();
    final popularCompetitions = state.competitions.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Prestify',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.lightBlue,
                            fontWeight: FontWeight.w800,
                          ),
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
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Halo, ${student.name}',
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temukan tim, dosen pembimbing, dan peluang lomba terbaik.',
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
                  CustomCard(
                    color: AppColors.deepNavy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppColors.accentYellow,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profil Skill',
                                    style: AppTextStyles.subtitle.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Text(
                                    '${student.program} - Angkatan ${student.year}',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.lightBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: student.skills
                              .map(
                                (skill) => SkillChip(
                                  label: skill,
                                  backgroundColor: AppColors.white.withAlpha(
                                    34,
                                  ),
                                  textColor: AppColors.white,
                                  compact: true,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  if (state.isTeamsLoading || state.isCompetitionsLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      minHeight: 4,
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.lightBlue,
                    ),
                  ],
                  if (state.apiNotice != null ||
                      state.teamError != null ||
                      state.competitionError != null) ...[
                    const SizedBox(height: 12),
                    CustomCard(
                      color: AppColors.lightBlue,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        state.apiNotice ??
                            state.teamError ??
                            state.competitionError ??
                            '',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _ShortcutGrid(onNavigate: onNavigate),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Rekomendasi Tim',
                    actionLabel: 'Lihat semua',
                    onAction: () => onNavigate(1),
                  ),
                  const SizedBox(height: 10),
                  ...recommendedTeams.map(
                    (team) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamDetailScreen(teamId: team.id),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    team.name,
                                    style: AppTextStyles.subtitle,
                                  ),
                                ),
                                SkillChip(
                                  label: '${team.matchingScore}%',
                                  backgroundColor: AppColors.successGreen
                                      .withAlpha(32),
                                  textColor: AppColors.successGreen,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              team.competitionName,
                              style: AppTextStyles.muted,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: team.matchingScore / 100,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(99),
                              backgroundColor: AppColors.lightBlue,
                              color: AppColors.successGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SectionHeader(title: 'Lomba Populer'),
                  const SizedBox(height: 10),
                  ...popularCompetitions.map(
                    (competition) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    competition.name,
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${competition.category} - ${competition.interestCount} peminat',
                                    style: AppTextStyles.muted,
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _ShortcutItem('Cari Tim', Icons.groups_rounded, () => onNavigate(1)),
      _ShortcutItem(
        'Cari Lomba',
        Icons.emoji_events_rounded,
        () => onNavigate(1),
      ),
      _ShortcutItem(
        'Dosen Pembimbing',
        Icons.co_present_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LecturerFinderScreen()),
        ),
      ),
      _ShortcutItem('Portofolio', Icons.badge_rounded, () => onNavigate(4)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return GridView.builder(
          itemCount: shortcuts.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.75 : 1.35,
          ),
          itemBuilder: (context, index) {
            final item = shortcuts[index];
            return CustomCard(
              onTap: item.onTap,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: AppColors.primaryBlue,
                      size: 21,
                    ),
                  ),
                  Text(
                    item.label,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}
